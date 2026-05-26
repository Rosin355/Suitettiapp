import Foundation

enum NotificationContentType: String, Codable {
    case article, event, document
}

struct NotificationDeepLink: Hashable {
    let id: UUID
    let contentType: NotificationContentType
    let slug: String

    init(id: UUID, contentType: NotificationContentType, slug: String) {
        self.id          = id
        self.contentType = contentType
        self.slug        = slug
    }

    // Parse from UNNotificationResponse userInfo — APNs-ready payload structure
    init?(userInfo: [AnyHashable: Any]) {
        guard
            let typeRaw  = userInfo["contentType"] as? String,
            let type     = NotificationContentType(rawValue: typeRaw),
            let idString = userInfo["id"] as? String,
            let id       = UUID(uuidString: idString),
            let slug     = userInfo["slug"] as? String
        else { return nil }
        self.id          = id
        self.contentType = type
        self.slug        = slug
    }

    var userInfo: [String: Any] {
        ["contentType": contentType.rawValue, "id": id.uuidString, "slug": slug]
    }
}
