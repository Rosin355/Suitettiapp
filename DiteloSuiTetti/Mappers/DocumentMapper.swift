import Foundation

private let uploadedFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "it_IT")
    f.dateFormat = "d MMM yyyy"
    return f
}()

extension DocumentDTO {
    func toDocument() -> Document {
        let uploaded = dataCaricamento.map { uploadedFormatter.string(from: $0) } ?? "Data non disponibile"
        return Document(
            id:          id,
            title:       titolo,
            slug:        slug,
            type:        tipo,
            category:    categoria,
            description: descrizione,
            url:         url.flatMap { URL(string: $0) },
            uploadedAt:  uploaded,
            // Sort key must match the displayed "Caricato il" date (derived from
            // dataCaricamento only). Using updatedAt as a fallback would hoist a
            // re-edited old PDF and let a doc shown as "Data non disponibile" sort
            // above dated ones — so a document with no upload date sorts last.
            publishedAt: dataCaricamento,
            updatedAt:   updatedAt,
            syncVersion: syncVersion
        )
    }
}
