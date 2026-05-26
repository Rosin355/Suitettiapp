import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    // Pending navigation targets set by deep-link resolution
    @State private var pendingArticle:  Article?
    @State private var pendingEvent:    Event?
    @State private var pendingDocument: Document?

    @Environment(AppDeepLinkRouter.self) private var router
    @Environment(ArticleStore.self)      private var articleStore
    @Environment(EventStore.self)        private var eventStore
    @Environment(DocumentStore.self)     private var documentStore

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                NavigationStack {
                    HomeView(selectedTab: $selectedTab)
                        .navigationDestination(isPresented: Binding(
                            get: { pendingEvent != nil },
                            set: { if !$0 { pendingEvent = nil } }
                        )) {
                            if let e = pendingEvent { EventDetailView(event: e) }
                        }
                        .navigationDestination(isPresented: Binding(
                            get: { pendingDocument != nil },
                            set: { if !$0 { pendingDocument = nil } }
                        )) {
                            if let d = pendingDocument { DocumentDetailView(document: d) }
                        }
                }
            }
            Tab("Articoli", systemImage: "doc.text.fill", value: AppTab.articoli) {
                NavigationStack {
                    ArticoliView()
                        .navigationTitle("Articoli")
                        .navigationDestination(isPresented: Binding(
                            get: { pendingArticle != nil },
                            set: { if !$0 { pendingArticle = nil } }
                        )) {
                            if let a = pendingArticle { ArticleDetailView(article: a) }
                        }
                }
            }
            Tab("Sostieni", systemImage: "heart.fill", value: AppTab.sostieni) {
                NavigationStack {
                    SosteniView()
                        .navigationTitle("Sostieni")
                }
            }
        }
        .tint(.brandRed)
        // Notification tap while app is running
        .onChange(of: router.pendingNotificationLink) { _, link in
            guard let link else { return }
            if router.contentDidLoad {
                _ = router.consumePendingNotificationLink()
                resolveDeepLink(link)
            }
            // else: defer to the contentDidLoad observer below
        }
        // Content loaded — retry any pending cold-launch deep link
        .onChange(of: router.contentDidLoad) { _, loaded in
            guard loaded else { return }
            if let link = router.consumePendingNotificationLink() {
                resolveDeepLink(link)
            }
        }
        // Handle link already set before ContentView appeared (cold launch)
        .onAppear {
            if router.contentDidLoad, let link = router.consumePendingNotificationLink() {
                resolveDeepLink(link)
            }
        }
    }

    // MARK: - Deep link resolution

    private func resolveDeepLink(_ link: NotificationDeepLink) {
        switch link.contentType {
        case .article:
            let article = articleStore.articles.first { $0.id == link.id }
                ?? articleStore.articles.first { $0.slug == link.slug }
            pendingArticle = article
            selectedTab = .articoli

        case .event:
            if let event = eventStore.events.first(where: { $0.id == link.id })
                ?? eventStore.events.first(where: { $0.slug == link.slug }) {
                pendingEvent = event
            }
            selectedTab = .home

        case .document:
            if let document = documentStore.documents.first(where: { $0.id == link.id })
                ?? documentStore.documents.first(where: { $0.slug == link.slug }) {
                pendingDocument = document
            }
            selectedTab = .home
        }
    }
}

#Preview {
    ContentView()
        .environment(ArticleStore(service: StubEditorialService()))
        .environment(EventStore(service: StubEventService()))
        .environment(DocumentStore(service: StubDocumentService()))
        .environment(AppDeepLinkRouter.shared)
}
