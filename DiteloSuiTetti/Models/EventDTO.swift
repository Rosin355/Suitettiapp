import Foundation

struct EventDTO: Decodable {
    let id: UUID
    let titolo: String
    let slug: String
    let tipo: String
    let dataEvento: String   // "YYYY-MM-DD" date-only — parse when building Event UI model
    let ora: String
    let luogo: String
    let descrizione: String
    let link: String?
    let immagineUrl: String?
    let updatedAt: Date
    let syncVersion: Int
}
