import Foundation

struct EventDTO: Decodable {
    let id: UUID
    let titolo: String
    let slug: String
    let tipo: String
    let dataEvento: String   // "YYYY-MM-DD" date-only — parse when building Event UI model
    let ora: String?         // backend may send null — optional so it never drops the event
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

        // Only id and titolo are hard-required: a malformed event must never drop
        // from the list unless its identity is missing. Every other field tolerates
        // null/missing/wrong-type by falling back to a safe default — mirroring the
        // resilient DocumentDTO pattern. The mapper already renders an event with an
        // empty dataEvento as "undated" rather than discarding it.
        id          = try c.decode(UUID.self,   forKey: .id)
        titolo      = try c.decode(String.self, forKey: .titolo)
        slug        = (try? c.decode(String.self, forKey: .slug)) ?? id.uuidString
        tipo        = (try? c.decodeIfPresent(String.self, forKey: .tipo)) ?? ""
        dataEvento  = (try? c.decodeIfPresent(String.self, forKey: .dataEvento)) ?? ""
        // `ora` is frequently null in the backend; decodeIfPresent yields nil for
        // both missing keys and explicit JSON null, so a null time never throws.
        // `try?` flattens the result to String?, also tolerating a wrong type.
        ora         = try? c.decodeIfPresent(String.self, forKey: .ora)
        luogo       = (try? c.decodeIfPresent(String.self, forKey: .luogo)) ?? ""
        descrizione = (try? c.decodeIfPresent(String.self, forKey: .descrizione)) ?? ""
        link        = try? c.decodeIfPresent(String.self, forKey: .link)
        immagineUrl = try? c.decodeIfPresent(String.self, forKey: .immagineUrl)
        syncVersion = (try? c.decodeIfPresent(Int.self, forKey: .syncVersion)) ?? 0

        updatedAt = try? c.decode(Date.self, forKey: .updatedAt)
        if updatedAt == nil {
            NSLog("[EventDTO] ⚠️ updatedAt missing/invalid for slug '%@'", slug)
        }

        let lossyAtts = (try? c.decode([Lossy<AttachmentDTO>].self, forKey: .attachments))
            ?? (try? c.decode([Lossy<AttachmentDTO>].self, forKey: .allegati))
            ?? []
        attachments = lossyAtts.compactMap(\.value).map { $0.toRelatedDocument() }
    }
}
