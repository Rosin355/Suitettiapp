import Foundation

struct EditorialSyncCoordinator {
    func syncAll() async throws -> EditorialSyncPayload {
        #if DEBUG
        print("[EditorialSyncCoordinator] ▶ sync started")
        #endif
        do {
            let response: EditorialSyncResponseDTO = try await APIClient.fetch(AppEnvironment.syncEditorialEndpoint)
            let articles  = response.articles.map  { $0.toArticle()  }
            let events    = response.events.map    { $0.toEvent()    }
            let documents = response.documents.map { $0.toDocument() }
            #if DEBUG
            print("[EditorialSyncCoordinator] ✓ sync succeeded — articles: \(articles.count), events: \(events.count), documents: \(documents.count)")
            let upcoming = events.filter(\.isUpcoming).count
            let past     = events.filter(\.isPast).count
            let undated  = events.filter(\.isUndated).count
            print("[EditorialSyncCoordinator]   events breakdown — upcoming: \(upcoming), past: \(past), undated: \(undated)")
            #endif
            return EditorialSyncPayload(
                articles:   articles,
                events:     events,
                documents:  documents,
                serverTime: response.serverTime
            )
        } catch {
            #if DEBUG
            print("[EditorialSyncCoordinator] ✗ sync failed — \(error)")
            #endif
            throw error
        }
    }
}
