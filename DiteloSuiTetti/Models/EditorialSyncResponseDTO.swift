import Foundation

struct EditorialSyncResponseDTO: Decodable {
    let serverTime: Date
    let articles: [ArticleDTO]
    let events: [EventDTO]
    let documents: [DocumentDTO]
}
