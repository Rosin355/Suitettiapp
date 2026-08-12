import SwiftData
import Foundation

@MainActor
final class EditorialCacheRepository {

    enum CacheError: LocalizedError {
        case storeUnavailable

        var errorDescription: String? {
            "La cache locale non è disponibile su questo dispositivo."
        }
    }

    /// Nil only if the on-disk store could not be opened *and* could not be rebuilt.
    /// The app stays fully functional in that state — it just syncs from the network
    /// on every launch instead of restoring cached content.
    private let container: ModelContainer?

    /// Editorial cache schema version. Bump whenever the cached shape or the
    /// ordering semantics change so stale rows are purged on next launch.
    /// v2 (2026-06-09): added `publishedAt` to articles/documents for date-descending sort.
    ///
    /// Not bumped for `CachedEvent.isFeatured` (2026-08-12): the property carries a
    /// default value, so SwiftData migrates existing stores automatically and the
    /// user keeps their offline content. Old rows read back as `isFeatured = false`,
    /// which is the correct pre-sync state — no banner until the backend says so.
    private static let schemaVersion = 2
    private static let schemaVersionKey = "editorialCacheSchemaVersion"

    init() {
        let schema = Schema([CachedArticle.self, CachedEvent.self, CachedDocument.self])
        container = Self.openStore(schema: schema)
        migrateSchemaIfNeeded()
    }

    /// Opens the persistent store, rebuilding it from scratch if it cannot be
    /// migrated. The editorial cache is a disposable mirror of the sync payload, so
    /// discarding it is always recoverable — crashing on launch is not, which is why
    /// this never force-tries.
    private static func openStore(schema: Schema) -> ModelContainer? {
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: onDisk)
        } catch {
            NSLog("[EditorialCache] ✗ store open failed — discarding and rebuilding: %@", "\(error)")
            SyncLogger.shared.append("EditorialCache store open FAILED — rebuilding: \(error)")
        }

        // Second chance: drop the incompatible store file and start clean. Clearing the
        // bookkeeping keys too, so the next launch treats this as a first run.
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: schemaVersionKey)
        defaults.removeObject(forKey: "lastSuccessfulSyncDate")
        let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path() + suffix))
        }
        do {
            return try ModelContainer(for: schema, configurations: onDisk)
        } catch {
            NSLog("[EditorialCache] ✗ rebuild failed — running without a persistent cache: %@", "\(error)")
            SyncLogger.shared.append("EditorialCache rebuild FAILED — no persistent cache: \(error)")
            return nil
        }
    }

    /// One-time purge of stale editorial cache when the schema version changes.
    /// After clearing, `loadPayload()` returns nil so the app performs a fresh
    /// sync and repopulates with dated, correctly-sorted content.
    private func migrateSchemaIfNeeded() {
        guard let container else { return }
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
        guard let container else { return nil }
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
        guard let container else { throw CacheError.storeUnavailable }
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
