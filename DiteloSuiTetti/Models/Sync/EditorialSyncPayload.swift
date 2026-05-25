import Foundation

struct EditorialSyncPayload {
    let articles:   [Article]
    let events:     [Event]
    let documents:  [Document]
    let serverTime: Date
}
