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
    let updatedAt: Date?
    let syncVersion: Int
    /// PDF/document attachments decoded from `attachments` or `allegati` array.
    let attachments: [RelatedDocument]

    private enum CodingKeys: String, CodingKey {
        case id, titolo, slug, tipo, dataEvento, ora, luogo, descrizione
        case link, immagineUrl, updatedAt, syncVersion
        case attachments, allegati
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        titolo      = try c.decode(String.self, forKey: .titolo)
        slug        = try c.decode(String.self, forKey: .slug)
        tipo        = try c.decode(String.self, forKey: .tipo)
        dataEvento  = try c.decode(String.self, forKey: .dataEvento)
        ora         = try c.decode(String.self, forKey: .ora)
        luogo       = try c.decode(String.self, forKey: .luogo)
        descrizione = try c.decode(String.self, forKey: .descrizione)
        link        = try c.decodeIfPresent(String.self, forKey: .link)
        immagineUrl = try c.decodeIfPresent(String.self, forKey: .immagineUrl)
        syncVersion = try c.decode(Int.self,    forKey: .syncVersion)

        updatedAt = try? c.decode(Date.self, forKey: .updatedAt)
        if updatedAt == nil {
            NSLog("[EventDTO] ⚠️ updatedAt missing/invalid for slug '%@'", slug)
        }

        let rawAttachments = (try? c.decode([AttachmentDTO].self, forKey: .attachments))
            ?? (try? c.decode([AttachmentDTO].self, forKey: .allegati))
            ?? []
        attachments = rawAttachments.map { $0.toRelatedDocument() }
    }
}
