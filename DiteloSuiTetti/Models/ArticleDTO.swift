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
    /// PDF/document attachments decoded from `attachments` or `allegati` array.
    let attachments: [RelatedDocument]

    private enum CodingKeys: String, CodingKey {
        case id, titolo, slug, categoria, dataPubblicazione, estratto, contenuto
        case immagineUrl, updatedAt, syncVersion
        case attachments, allegati
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Only id + titolo are hard-required. Every other field tolerates null/missing
        // so a backend article is NEVER dropped at decode for an empty field — e.g. an
        // "Eventi" item with `estratto: null` (this was the bug that hid "Grazie!!"),
        // or any category such as "Rassegna Stampa". Mirrors the resilient DocumentDTO/
        // EventDTO decoders.
        id        = try c.decode(UUID.self,   forKey: .id)
        titolo    = try c.decode(String.self, forKey: .titolo)
        slug      = (try? c.decode(String.self, forKey: .slug)) ?? id.uuidString
        categoria = (try? c.decodeIfPresent(String.self, forKey: .categoria)) ?? ""
        estratto  = (try? c.decodeIfPresent(String.self, forKey: .estratto)) ?? ""
        contenuto = (try? c.decodeIfPresent(String.self, forKey: .contenuto)) ?? ""
        immagineUrl = try? c.decodeIfPresent(String.self, forKey: .immagineUrl)
        syncVersion = (try? c.decodeIfPresent(Int.self, forKey: .syncVersion)) ?? 0

        dataPubblicazione = try? c.decode(Date.self, forKey: .dataPubblicazione)
        if dataPubblicazione == nil {
            NSLog("[ArticleDTO] ⚠️ dataPubblicazione missing/invalid for slug '%@'", slug)
        }

        updatedAt = try? c.decode(Date.self, forKey: .updatedAt)
        if updatedAt == nil {
            NSLog("[ArticleDTO] ⚠️ updatedAt missing/invalid for slug '%@'", slug)
        }

        let lossyAtts = (try? c.decode([Lossy<AttachmentDTO>].self, forKey: .attachments))
            ?? (try? c.decode([Lossy<AttachmentDTO>].self, forKey: .allegati))
            ?? []
        attachments = lossyAtts.compactMap(\.value).map { $0.toRelatedDocument() }
    }
}
