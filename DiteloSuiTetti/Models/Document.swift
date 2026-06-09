import Foundation

struct Document: Identifiable {
    let id: UUID
    let title: String
    let slug: String
    let type: String
    let category: String
    let description: String
    let url: URL?
    let uploadedAt: String
    /// Raw upload/publication date used for ordering. Display uses `uploadedAt`.
    let publishedAt: Date?
    let updatedAt: Date?
    let syncVersion: Int

    // Explicit init keeps `publishedAt` optional so preview/fixture call sites
    // that predate date-ordering continue to compile without it.
    init(
        id: UUID,
        title: String,
        slug: String,
        type: String,
        category: String,
        description: String,
        url: URL?,
        uploadedAt: String,
        publishedAt: Date? = nil,
        updatedAt: Date?,
        syncVersion: Int
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.type = type
        self.category = category
        self.description = description
        self.url = url
        self.uploadedAt = uploadedAt
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.syncVersion = syncVersion
    }
}
