import Foundation

// Backend currently returns no documents. Placeholder ready for when they are added.
struct DocumentDTO: Decodable {
    let id: UUID
    let titolo: String
    let slug: String
    let updatedAt: Date
    let syncVersion: Int
}
