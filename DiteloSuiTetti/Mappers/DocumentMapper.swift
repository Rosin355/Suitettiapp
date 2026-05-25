import Foundation

private let uploadedFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "it_IT")
    f.dateFormat = "d MMM yyyy"
    return f
}()

extension DocumentDTO {
    func toDocument() -> Document {
        Document(
            id:          id,
            title:       titolo,
            slug:        slug,
            type:        tipo,
            category:    categoria,
            description: descrizione,
            url:         url.flatMap { URL(string: $0) },
            uploadedAt:  uploadedFormatter.string(from: dataCaricamento),
            updatedAt:   updatedAt,
            syncVersion: syncVersion
        )
    }
}
