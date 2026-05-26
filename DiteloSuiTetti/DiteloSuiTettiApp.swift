import SwiftUI

@main
struct DiteloSuiTettiApp: App {
    @State private var store         = ArticleStore()
    @State private var eventStore    = EventStore()
    @State private var documentStore = DocumentStore()
    @State private var cache         = EditorialCacheRepository()
    private let coordinator          = EditorialSyncCoordinator()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasSeenOnboarding {
                    ContentView()
                        .environment(store)
                        .environment(eventStore)
                        .environment(documentStore)
                        .task { await loadContent() }
                        .transition(.opacity)
                } else {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: hasSeenOnboarding)
        }
    }

    // MARK: - Content loading (runs when ContentView first appears)

    private func loadContent() async {
        let cached = cache.loadPayload()
        let hasCachedContent = cached != nil

        if let cached {
            store.replace(with: cached.articles)
            eventStore.replace(with: cached.events)
            documentStore.replace(with: cached.documents)
        } else {
            store.beginLoading()
            eventStore.beginLoading()
            documentStore.beginLoading()
        }

        do {
            let payload = try await coordinator.syncAll()
            store.replace(with: payload.articles)
            eventStore.replace(with: payload.events)
            documentStore.replace(with: payload.documents)
            try? cache.clearAndReplace(with: payload)
        } catch {
            if hasCachedContent {
                store.setOfflineWarning()
                eventStore.setOfflineWarning()
                documentStore.setOfflineWarning()
            } else {
                let message = error.localizedDescription
                store.failedLoading(message: message)
                eventStore.failedLoading(message: message)
                documentStore.failedLoading(message: message)
            }
        }
    }
}
