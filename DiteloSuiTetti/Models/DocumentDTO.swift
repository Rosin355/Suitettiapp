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
        // file_url, pdf_url, document_url, attachment_url, public_url, legacy_url)
        case url, fileUrl, pdfUrl, documentUrl, attachmentUrl, publicUrl, legacyUrl, link
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

        // URL: collect every known backend field, then PREFER a direct-PDF URL over
        // an HTML page URL (e.g. a legacy WordPress permalink). If the backend ever
        // sends both a public page URL and a PDF URL, the PDF wins.
        let urlCandidates: [String] = [
            (try? c.decode(String.self, forKey: .url)).nonEmpty,
            (try? c.decode(String.self, forKey: .fileUrl)).nonEmpty,
            (try? c.decode(String.self, forKey: .pdfUrl)).nonEmpty,
            (try? c.decode(String.self, forKey: .documentUrl)).nonEmpty,
            (try? c.decode(String.self, forKey: .attachmentUrl)).nonEmpty,
            (try? c.decode(String.self, forKey: .publicUrl)).nonEmpty,
            (try? c.decode(String.self, forKey: .legacyUrl)).nonEmpty,
            (try? c.decode(String.self, forKey: .link)).nonEmpty,
        ].compactMap { $0 }

        func isPDFLike(_ string: String) -> Bool {
            (URL(string: string)?.pathExtension.lowercased() ?? "") == "pdf"
        }
        url = urlCandidates.first(where: isPDFLike) ?? urlCandidates.first

        // Diagnostic: surface exactly the documents whose only URL is NOT a direct PDF
        // (a page link or a non-.pdf object) — these are the ones that 404 or render HTML.
        if let chosen = url, !isPDFLike(chosen) {
            NSLog("[DocumentURL] ⚠️ '%@' resolved to a non-PDF URL: %@ (%d candidate field(s))",
                  titolo, chosen, urlCandidates.count)
        }

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
