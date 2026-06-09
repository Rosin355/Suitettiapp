import SwiftData
import Foundation

@MainActor
final class EditorialCacheRepository {
    private let container: ModelContainer

    /// Editorial cache schema version. Bump whenever the cached shape or the
    /// ordering semantics change so stale rows are purged on next launch.
    /// v2 (2026-06-09): added `publishedAt` to articles/documents for date-descending sort.
    private static let schemaVersion = 2
    private static let schemaVersionKey = "editorialCacheSchemaVersion"

    init() {
        let schema = Schema([CachedArticle.self, CachedEvent.self, CachedDocument.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // Force-try is intentional: a SwiftData schema failure means the app is fundamentally broken.
        container = try! ModelContainer(for: schema, configurations: config)
        migrateSchemaIfNeeded()
    }

    /// One-time purge of stale editorial cache when the schema version changes.
    /// After clearing, `loadPayload()` returns nil so the app performs a fresh
    /// sync and repopulates with dated, correctly-sorted content.
    private func migrateSchemaIfNeeded() {
        let defaults = UserDefaults.standard
        let stored = defaults.integer(forKey: Self.schemaVersionKey)   // 0 if never set
        guard stored != Self.schemaVersion else { return }
        NSLog("[EditorialCache] schema bump — clearing stale editorial cache")
        SyncLogger.shared.append("EditorialCache schema bump \(stored) → \(Self.schemaVersion) — clearing stale cache")
        let context = container.mainContext
        do {
            try context.delete(model: CachedArticle.self)
            try context.delete(model: CachedEvent.self)
            try context.delete(model: CachedDocument.self)
            try context.save()
            // Only advance the version after a confirmed purge, otherwise leave it
            // unchanged so the clear is retried on the next launch.
            defaults.removeObject(forKey: "lastSuccessfulSyncDate")
            defaults.set(Self.schemaVersion, forKey: Self.schemaVersionKey)
        } catch {
            NSLog("[EditorialCache] ✗ stale-cache purge failed — will retry next launch: %@", "\(error)")
            SyncLogger.shared.append("EditorialCache purge FAILED — will retry: \(error)")
        }
    }

    func loadPayload() -> EditorialSyncPayload? {
        let context = container.mainContext
        let articles  = (try? context.fetch(FetchDescriptor<CachedArticle>())) ?? []
        let events    = (try? context.fetch(FetchDescriptor<CachedEvent>())) ?? []
        let documents = (try? context.fetch(FetchDescriptor<CachedDocument>())) ?? []
        guard !articles.isEmpty || !events.isEmpty || !documents.isEmpty else { return nil }
        let serverTime = UserDefaults.standard.object(forKey: "lastSuccessfulSyncDate") as? Date ?? .distantPast
        return EditorialSyncPayload(
            articles:   EditorialSort.articlesByDateDescending(articles.map { $0.toArticle() }),
            events:     events.map { $0.toEvent() },
            documents:  EditorialSort.documentsByDateDescending(documents.map { $0.toDocument() }),
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
