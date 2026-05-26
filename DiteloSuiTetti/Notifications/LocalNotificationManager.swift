import UserNotifications

@MainActor
final class LocalNotificationManager {
    static let shared = LocalNotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let sentIDsKey = "sentLocalNotificationIDs"

    // MARK: - Authorization

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Scheduling (one method per content type for type safety)

    func scheduleIfNeeded(for article: Article) async {
        await schedule(
            id: "article.\(article.id.uuidString)",
            subtitle: "Nuovo articolo",
            body: article.title,
            deepLink: NotificationDeepLink(id: article.id, contentType: .article, slug: article.slug)
        )
    }

    func scheduleIfNeeded(for event: Event) async {
        await schedule(
            id: "event.\(event.id.uuidString)",
            subtitle: "Nuovo evento",
            body: event.title,
            deepLink: NotificationDeepLink(id: event.id, contentType: .event, slug: event.slug)
        )
    }

    func scheduleIfNeeded(for document: Document) async {
        await schedule(
            id: "document.\(document.id.uuidString)",
            subtitle: "Nuovo documento",
            body: document.title,
            deepLink: NotificationDeepLink(id: document.id, contentType: .document, slug: document.slug)
        )
    }

    // MARK: - Private

    private func schedule(
        id: String,
        subtitle: String,
        body: String,
        deepLink: NotificationDeepLink
    ) async {
        guard await authorizationStatus() == .authorized else { return }
        guard !hasSent(id) else { return }

        let content          = UNMutableNotificationContent()
        content.title        = "Ditelo sui Tetti"
        content.subtitle     = subtitle
        content.body         = body
        content.sound        = .default
        content.userInfo     = deepLink.userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await center.add(request)
        markSent(id)
    }

    private func hasSent(_ id: String) -> Bool {
        sentIDs.contains(id)
    }

    private func markSent(_ id: String) {
        var ids = sentIDs
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: sentIDsKey)
    }

    private var sentIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: sentIDsKey) ?? [])
    }
}
