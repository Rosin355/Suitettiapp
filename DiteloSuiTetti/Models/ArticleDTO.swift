import Foundation

struct ArticleDTO: Decodable {
    let id: UUID
    let titolo: String
    let slug: String
    let categoria: String
    let dataPubblicazione: Date?
    let estratto: String
    let contenuto: String
    let immagineUrl: String?
    let updatedAt: Date?
    let syncVersion: Int

    private enum CodingKeys: String, CodingKey {
        case id, titolo, slug, categoria, dataPubblicazione, estratto, contenuto, immagineUrl, updatedAt, syncVersion
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(UUID.self,   forKey: .id)
        titolo   = try c.decode(String.self, forKey: .titolo)
        slug     = try c.decode(String.self, forKey: .slug)
        categoria = try c.decode(String.self, forKey: .categoria)
        estratto = try c.decode(String.self, forKey: .estratto)
        contenuto = try c.decode(String.self, forKey: .contenuto)
        immagineUrl = try c.decodeIfPresent(String.self, forKey: .immagineUrl)
        syncVersion = try c.decode(Int.self, forKey: .syncVersion)

        dataPubblicazione = try? c.decode(Date.self, forKey: .dataPubblicazione)
        if dataPubblicazione == nil {
            NSLog("[ArticleDTO] ⚠️ dataPubblicazione missing/invalid for slug '%@'", slug)
        }

        updatedAt = try? c.decode(Date.self, forKey: .updatedAt)
        if updatedAt == nil {
            NSLog("[ArticleDTO] ⚠️ updatedAt missing/invalid for slug '%@'", slug)
        }
    }
}
