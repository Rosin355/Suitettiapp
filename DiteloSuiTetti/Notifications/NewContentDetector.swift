import Foundation

enum NewContentDetector {
    struct Result {
        var newArticle:  Article?
        var newEvent:    Event?
        var newDocument: Document?
    }

    // Returns up to one new item per content type.
    // Only runs when previousPayload is non-nil (not on first install).
    static func detect(
        previous: EditorialSyncPayload,
        fresh:    EditorialSyncPayload
    ) -> Result {
        let prevArticleIDs  = Set(previous.articles.map(\.id))
        let prevEventIDs    = Set(previous.events.map(\.id))
        let prevDocumentIDs = Set(previous.documents.map(\.id))

        return Result(
            newArticle:  fresh.articles.first  { !prevArticleIDs.contains($0.id) },
            newEvent:    fresh.events.first    { !prevEventIDs.contains($0.id) },
            newDocument: fresh.documents.first { !prevDocumentIDs.contains($0.id) }
        )
    }
}
