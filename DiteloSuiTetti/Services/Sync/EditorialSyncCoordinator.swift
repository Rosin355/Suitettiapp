import Foundation

struct EditorialSyncCoordinator {
    func syncAll() async throws -> EditorialSyncPayload {
        NSLog("[EditorialSyncCoordinator] ▶ sync started — endpoint: %@",
              AppEnvironment.syncEditorialEndpoint.absoluteString)
        SyncLogger.shared.append("sync started")
        do {
            let response: EditorialSyncResponseDTO = try await APIClient.fetch(AppEnvironment.syncEditorialEndpoint)
            // Sort at the source so the payload (and downstream NewContentDetector,
            // which picks `.first` new item) reflect newest-first order, never backend order.
            let articles  = EditorialSort.articlesByDateDescending(response.articles.map { $0.toArticle() })
            let events    = response.events.map { $0.toEvent() }
            let documents = EditorialSort.documentsByDateDescending(response.documents.map { $0.toDocument() })
            let upcoming  = events.filter(\.isUpcoming).count
            let past      = events.filter(\.isPast).count
            let undated   = events.filter(\.isUndated).count
            NSLog("[EditorialSyncCoordinator] ✓ sync OK — articles: %d, events: %d (upcoming:%d past:%d undated:%d), documents: %d",
                  articles.count, events.count, upcoming, past, undated, documents.count)
            SyncLogger.shared.append("sync OK — articles:\(articles.count) events:\(events.count) docs:\(documents.count)")
            SyncLogger.shared.recordSyncResult(articles: articles.count, events: events.count, documents: documents.count)
            Self.logDiagnostics(articles: articles, documents: documents, events: events)
            return EditorialSyncPayload(
                articles:   articles,
                events:     events,
                documents:  documents,
                serverTime: response.serverTime
            )
        } catch {
            NSLog("[EditorialSyncCoordinator] ✗ sync failed — %@", "\(error)")
            SyncLogger.shared.append("sync FAIL: \(error)")
            throw error
        }
    }

    // MARK: - Post-sync diagnostics

    /// Logs the first 5 of each content type in final (sorted) display order so a
    /// glance at the device console confirms the latest content surfaces first.
    private static func logDiagnostics(articles: [Article], documents: [Document], events: [Event]) {
        let iso = ISO8601DateFormatter()
        func stamp(_ date: Date?) -> String { date.map { iso.string(from: $0) } ?? "nil" }

        for (i, a) in articles.prefix(5).enumerated() {
            NSLog("[SyncDiag] article[%d]: '%@' date=%@", i, a.title, stamp(a.publishedAt))
        }
        for (i, d) in documents.prefix(5).enumerated() {
            NSLog("[SyncDiag] document[%d]: '%@' date=%@ url=%@",
                  i, d.title, stamp(d.publishedAt), d.url == nil ? "nil" : "present")
        }
        for (i, e) in events.prefix(5).enumerated() {
            NSLog("[SyncDiag] event[%d]: '%@' rawDate=%@ upcoming=%@",
                  i, e.title, stamp(e.rawDate), e.isUpcoming ? "yes" : "no")
        }
    }
}
