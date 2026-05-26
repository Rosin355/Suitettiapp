import SwiftData
import Foundation

@MainActor
final class EditorialCacheRepository {
    private let container: ModelContainer

    init() {
        let schema = Schema([CachedArticle.self, CachedEvent.self, CachedDocument.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // Force-try is intentional: a SwiftData schema failure means the app is fundamentally broken.
        container = try! ModelContainer(for: schema, configurations: config)
    }

    func loadPayload() -> EditorialSyncPayload? {
        let context = container.mainContext
        let articles  = (try? context.fetch(FetchDescriptor<CachedArticle>())) ?? []
        let events    = (try? context.fetch(FetchDescriptor<CachedEvent>())) ?? []
        let documents = (try? context.fetch(FetchDescriptor<CachedDocument>())) ?? []
        guard !articles.isEmpty || !events.isEmpty || !documents.isEmpty else { return nil }
        let serverTime = UserDefaults.standard.object(forKey: "lastSuccessfulSyncDate") as? Date ?? .distantPast
        return EditorialSyncPayload(
            articles:   articles.map  { $0.toArticle()  },
            events:     events.map    { $0.toEvent()    },
            documents:  documents.map { $0.toDocument() },
            serverTime: serverTime
        )
    }

    func clearAndReplace(with payload: EditorialSyncPayload) throws {
        let context = container.mainContext
        try context.delete(model: CachedArticle.self)
        try context.delete(model: CachedEvent.self)
        try context.delete(model: CachedDocument.self)
        payload.articles.forEach  { context.insert(CachedArticle(from: $0))  }
        payload.events.forEach    { context.insert(CachedEvent(from: $0))    }
        payload.documents.forEach { context.insert(CachedDocument(from: $0)) }
        try context.save()
        UserDefaults.standard.set(Date(), forKey: "lastSuccessfulSyncDate")
    }
}
