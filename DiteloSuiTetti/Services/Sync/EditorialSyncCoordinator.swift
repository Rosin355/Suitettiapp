import Foundation

struct EditorialSyncCoordinator {
    func syncAll() async throws -> EditorialSyncPayload {
        NSLog("[EditorialSyncCoordinator] ▶ sync started — endpoint: %@",
              AppEnvironment.syncEditorialEndpoint.absoluteString)
        SyncLogger.shared.append("sync started")
        do {
            let response: EditorialSyncResponseDTO = try await APIClient.fetch(AppEnvironment.syncEditorialEndpoint)
            let articles  = response.articles.map  { $0.toArticle()   }
            let events    = response.events.map    { $0.toEvent()     }
            let documents = response.documents.map { $0.toDocument()  }
            let upcoming  = events.filter(\.isUpcoming).count
            let past      = events.filter(\.isPast).count
            let undated   = events.filter(\.isUndated).count
            NSLog("[EditorialSyncCoordinator] ✓ sync OK — articles: %d, events: %d (upcoming:%d past:%d undated:%d), documents: %d",
                  articles.count, events.count, upcoming, past, undated, documents.count)
            SyncLogger.shared.append("sync OK — articles:\(articles.count) events:\(events.count) docs:\(documents.count)")
            SyncLogger.shared.recordSyncResult(articles: articles.count, events: events.count, documents: documents.count)
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
}
