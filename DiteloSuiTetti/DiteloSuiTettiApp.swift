import SwiftUI

@main
struct DiteloSuiTettiApp: App {
    @State private var store         = ArticleStore()
    @State private var eventStore    = EventStore()
    @State private var documentStore = DocumentStore()
    private let coordinator          = EditorialSyncCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(eventStore)
                .environment(documentStore)
                .task {
                    store.beginLoading()
                    eventStore.beginLoading()
                    documentStore.beginLoading()
                    do {
                        let payload = try await coordinator.syncAll()
                        store.replace(with: payload.articles)
                        eventStore.replace(with: payload.events)
                        documentStore.replace(with: payload.documents)
                    } catch {
                        let message = error.localizedDescription
                        store.failedLoading(message: message)
                        eventStore.failedLoading(message: message)
                        documentStore.failedLoading(message: message)
                    }
                }
        }
    }
}
