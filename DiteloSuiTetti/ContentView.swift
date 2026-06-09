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
    @Environment(AppVersionStore.self)   private var appVersionStore

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
            Tab("Documenti", systemImage: "folder.fill", value: AppTab.documenti) {
                NavigationStack {
                    DocumentiView()
                        .navigationTitle("Documenti")
                        .navigationDestination(isPresented: Binding(
                            get: { pendingDocument != nil },
                            set: { if !$0 { pendingDocument = nil } }
                        )) {
                            if let d = pendingDocument { DocumentDetailView(document: d) }
                        }
                }
            }
            Tab("Chi siamo", systemImage: "info.circle.fill", value: AppTab.chiSiamo) {
                NavigationStack {
                    AboutView()
                        .navigationTitle("Chi siamo")
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
        // Soft update — dismissible sheet ("Aggiorna ora" / "Più tardi")
        .sheet(isPresented: softUpdateBinding) {
            if case let .soft(config) = appVersionStore.requirement {
                AppUpdateSheet(
                    config: config,
                    isForced: false,
                    onUpdate: { appVersionStore.openAppStore() },
                    onLater: { appVersionStore.dismissSoftUpdate() }
                )
                .presentationDetents([.medium])
            }
        }
        // Forced update — blocking full-screen cover, cannot be dismissed
        .fullScreenCover(isPresented: forcedUpdateBinding) {
            if case let .forced(config) = appVersionStore.requirement {
                AppUpdateSheet(
                    config: config,
                    isForced: true,
                    onUpdate: { appVersionStore.openAppStore() }
                )
                .interactiveDismissDisabled(true)
            }
        }
    }

    // MARK: - Update prompt bindings

    /// Presents the soft sheet; dismissing it (swipe or "Più tardi") records the
    /// dismissed version so it won't reappear for the same release.
    private var softUpdateBinding: Binding<Bool> {
        Binding(
            get: { if case .soft = appVersionStore.requirement { return true } else { return false } },
            set: { isShown in if !isShown { appVersionStore.dismissSoftUpdate() } }
        )
    }

    /// Presents the forced cover; the setter is a no-op so it cannot be dismissed.
    private var forcedUpdateBinding: Binding<Bool> {
        Binding(
            get: { appVersionStore.requirement.isForced },
            set: { _ in }
        )
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
            selectedTab = .documenti
        }
    }
}

#Preview {
    ContentView()
        .environment(ArticleStore(service: StubEditorialService()))
        .environment(EventStore(service: StubEventService()))
        .environment(DocumentStore(service: StubDocumentService()))
        .environment(AppVersionStore(service: StubAppVersionService()))
        .environment(AppDeepLinkRouter.shared)
}
