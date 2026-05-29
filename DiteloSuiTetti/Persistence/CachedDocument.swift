import SwiftData
import Foundation

@Model
final class CachedDocument {
    @Attribute(.unique) var id: UUID
    var title: String
    var slug: String
    var type: String
    var category: String
    var documentDescription: String
    var urlString: String?
    var uploadedAt: String
    var updatedAt: Date?
    var syncVersion: Int

    init(from document: Document) {
        id                  = document.id
        title               = document.title
        slug                = document.slug
        type                = document.type
        category            = document.category
        documentDescription = document.description
        urlString           = document.url?.absoluteString
        uploadedAt          = document.uploadedAt
        updatedAt           = document.updatedAt
        syncVersion         = document.syncVersion
    }

    func toDocument() -> Document {
        Document(
            id:          id,
            title:       title,
            slug:        slug,
            type:        type,
            category:    category,
            description: documentDescription,
            url:         urlString.flatMap { URL(string: $0) },
            uploadedAt:  uploadedAt,
            updatedAt:   updatedAt,
            syncVersion: syncVersion
        )
    }
}
