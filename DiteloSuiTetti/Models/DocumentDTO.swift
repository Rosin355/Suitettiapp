import Foundation

struct DocumentDTO: Decodable {
    let id: UUID
    let titolo: String
    let slug: String
    let tipo: String        // non-critical — defaults to ""
    let categoria: String   // non-critical — defaults to ""
    let descrizione: String // non-critical — defaults to ""
    let url: String?
    let dataCaricamento: Date?
    let updatedAt: Date?
    let syncVersion: Int    // non-critical — defaults to 0

    private enum CodingKeys: String, CodingKey {
        case id, slug
        // title fields: Italian and English variants
        case titolo, title
        // type
        case tipo, type
        // category
        case categoria, category
        // description
        case descrizione, description
        // url: multiple backend field name variants (snake_case mapped by decoder:
        // file_url, document_url, public_url)
        case url, fileUrl, documentUrl, link, publicUrl
        // dates
        case dataCaricamento, createdAt, updatedAt
        // version
        case syncVersion
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // id is the only truly required field — we cannot create a document without identity
        id = try c.decode(UUID.self, forKey: .id)

        // Slug defaults to id string if missing
        slug = (try? c.decode(String.self, forKey: .slug)) ?? id.uuidString

        // Title: Italian name first, then English, then placeholder
        titolo = (try? c.decode(String.self, forKey: .titolo)).nonEmpty
            ?? (try? c.decode(String.self, forKey: .title)).nonEmpty
            ?? "Documento"

        // Non-critical string fields — null/missing → empty string
        tipo = (try? c.decode(String.self, forKey: .tipo)).nonEmpty
            ?? (try? c.decode(String.self, forKey: .type)).nonEmpty
            ?? ""

        categoria = (try? c.decode(String.self, forKey: .categoria)).nonEmpty
            ?? (try? c.decode(String.self, forKey: .category)).nonEmpty
            ?? ""

        descrizione = (try? c.decode(String.self, forKey: .descrizione)).nonEmpty
            ?? (try? c.decode(String.self, forKey: .description)).nonEmpty
            ?? ""

        // URL: try all known field names the backend might use
        url = (try? c.decode(String.self, forKey: .url)).nonEmpty
            ?? (try? c.decode(String.self, forKey: .fileUrl)).nonEmpty
            ?? (try? c.decode(String.self, forKey: .documentUrl)).nonEmpty
            ?? (try? c.decode(String.self, forKey: .publicUrl)).nonEmpty
            ?? (try? c.decode(String.self, forKey: .link)).nonEmpty

        // Version — default 0 if missing
        syncVersion = (try? c.decode(Int.self, forKey: .syncVersion)) ?? 0

        // Dates — optional, try primary then fallback field name
        dataCaricamento = (try? c.decode(Date.self, forKey: .dataCaricamento))
            ?? (try? c.decode(Date.self, forKey: .createdAt))

        updatedAt = try? c.decode(Date.self, forKey: .updatedAt)
    }
}

private extension Optional where Wrapped == String {
    /// Returns nil for empty strings so `?? fallback` chains work correctly.
    var nonEmpty: String? { self.flatMap { $0.isEmpty ? nil : $0 } }
}
