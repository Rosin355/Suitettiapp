import Foundation

struct ArticleDTO: Decodable {
    let id: UUID
    let titolo: String
    let slug: String
    let categoria: String
    let dataPubblicazione: Date
    let estratto: String
    let contenuto: String
    let immagineUrl: String?
    let updatedAt: Date
    let syncVersion: Int
}
