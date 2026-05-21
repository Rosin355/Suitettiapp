import Foundation

struct DocumentDTO: Decodable {
    let id: UUID
    let titolo: String
    let slug: String
    let tipo: String
    let categoria: String
    let descrizione: String
    let url: String?
    let dataCaricamento: Date
    let updatedAt: Date
    let syncVersion: Int
}
