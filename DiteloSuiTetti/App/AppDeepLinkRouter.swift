import Foundation

@MainActor
@Observable
final class AppDeepLinkRouter {
    static let shared = AppDeepLinkRouter()
    private init() {}

    var pendingNotificationLink: NotificationDeepLink?

    // Set to true after loadContent() completes — ContentView uses this to
    // defer cold-launch deep link resolution until stores are populated.
    var contentDidLoad: Bool = false

    func handle(_ link: NotificationDeepLink) {
        pendingNotificationLink = link
    }

    func consumePendingNotificationLink() -> NotificationDeepLink? {
        defer { pendingNotificationLink = nil }
        return pendingNotificationLink
    }
}
