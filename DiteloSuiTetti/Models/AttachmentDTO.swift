import Foundation

/// Flexible decoder for a single PDF/document attachment on an article or event.
/// Handles varied field names the backend may use and never throws —
/// every field falls back gracefully so the parent array decode never fails.
struct AttachmentDTO: Decodable {
    let id: UUID
    let title: String
    let type: String
    let description: String
    let url: String?

    private enum CodingKeys: String, CodingKey {
        case id
        // title fallbacks: standard, Italian, and common file-metadata variants
        case title, titolo, name, attachmentName, filename
        case type, tipo
        case description, descrizione
        case url, fileUrl, pdfUrl, documentUrl, attachmentUrl, allegatoUrl, link
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id    = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        title = AttachmentDTO.first(c, keys: [.title, .name, .titolo, .attachmentName, .filename]) ?? "Allegato"
        type  = AttachmentDTO.first(c, keys: [.type, .tipo]) ?? ""
        description = AttachmentDTO.first(c, keys: [.description, .descrizione]) ?? ""
        url = AttachmentDTO.first(c, keys: [
            .url, .fileUrl, .pdfUrl, .documentUrl, .attachmentUrl, .allegatoUrl, .link
        ])
    }

    func toRelatedDocument() -> RelatedDocument {
        RelatedDocument(
            id: id,
            title: title,
            type: type.isEmpty ? "PDF" : type,
            description: description,
            url: url.flatMap { URL(string: $0) }
        )
    }

    private static func first(
        _ c: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> String? {
        for key in keys {
            if let v = try? c.decode(String.self, forKey: key), !v.isEmpty { return v }
        }
        return nil
    }
}
