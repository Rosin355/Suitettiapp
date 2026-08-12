import SwiftUI
import UIKit

@main
struct DiteloSuiTettiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Enlarge the shared URL cache so AsyncImage doesn't evict article images
        // between the Home tab load and ArticoliView render (default is only 20 MB).
        URLCache.shared = URLCache(
            memoryCapacity: 50_000_000,   // 50 MB
            diskCapacity:  200_000_000,   // 200 MB
            diskPath: nil
        )
    }

    @State private var store         = ArticleStore()
    @State private var eventStore    = EventStore()
    @State private var documentStore = DocumentStore()
    @State private var appVersionStore = AppVersionStore()
    @State private var cache         = EditorialCacheRepository()
    @State private var router        = AppDeepLinkRouter.shared
    private let coordinator          = EditorialSyncCoordinator()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding      = false
    @State private var showNotificationPrompt                             = false
    @State private var didInitialLoad                                     = false
    @Environment(\.scenePhase) private var scenePhase

    // Cache-invalidation bookkeeping.
    private static let signatureKey = "editorialContentSignature"
    private static let syncDateKey  = "lastSuccessfulSyncDate"
    /// On foreground resume, only re-sync if the last successful sync is older than this.
    private static let foregroundStaleThreshold: TimeInterval = 600  // 10 minutes

    // Screenshot capture mode: launch with --screenshots to bypass onboarding and inject
    // deterministic demo content. Use in Xcode scheme or App Store Connect automation.
    private let isScreenshotMode = ProcessInfo.processInfo.arguments.contains("--screenshots")

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasSeenOnboarding || isScreenshotMode {
                    ContentView()
                        .environment(store)
                        .environment(eventStore)
                        .environment(documentStore)
                        .environment(appVersionStore)
                        .environment(router)
                        .task { await loadContent() }
                        .task {
                            // Remote-config update check on launch (skipped for App Store
                            // screenshot automation). Never blocks content if it fails.
                            if !isScreenshotMode { await appVersionStore.check() }
                        }
                        // Refresh editorial content when returning to the foreground if
                        // the local cache has gone stale (does not block the UI).
                        .onChange(of: scenePhase) { _, newPhase in
                            if newPhase == .active {
                                Task { await refreshOnForegroundIfStale() }
                            }
                        }
                        .transition(.opacity)
                } else if showNotificationPrompt {
                    NotificationPermissionView(
                        onAllow: {
                            Task {
                                await LocalNotificationManager.shared.requestAuthorization()
                                let status = await LocalNotificationManager.shared.authorizationStatus()
                                if status == .authorized || status == .provisional || status == .ephemeral {
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                                hasSeenOnboarding = true
                            }
                        },
                        onSkip: { hasSeenOnboarding = true }
                    )
                    .transition(.opacity)
                } else {
                    OnboardingView {
                        Task {
                            let status = await LocalNotificationManager.shared.authorizationStatus()
                            // Skip pre-prompt if permission has already been answered
                            if status == .authorized || status == .provisional || status == .denied || status == .ephemeral {
                                hasSeenOnboarding = true
                            } else {
                                showNotificationPrompt = true
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: hasSeenOnboarding)
            .animation(.easeInOut(duration: 0.35), value: showNotificationPrompt)
        }
    }

    // MARK: - Content loading

    private func loadContent() async {
        if isScreenshotMode {
            store.replace(with: AppStorePreviewData.articles)
            eventStore.replace(with: AppStorePreviewData.events)
            documentStore.replace(with: AppStorePreviewData.documents)
            router.contentDidLoad = true
            return
        }

        let notifStatus = await LocalNotificationManager.shared.authorizationStatus()
        if notifStatus == .authorized || notifStatus == .provisional || notifStatus == .ephemeral {
            UIApplication.shared.registerForRemoteNotifications()
        }

        // Cache-first: show persisted content immediately, then sync fresh from origin.
        let cached = cache.loadPayload()
        let hasCachedContent = cached != nil

        if let cached {
            replaceStores(with: cached)
            // The banner can render from cache before the network answers (offline launch).
            NSLog("[FeaturedEvent] restored from cache: %@", eventStore.featuredEvent?.title ?? "nil")
        } else {
            store.beginLoading()
            eventStore.beginLoading()
            documentStore.beginLoading()
        }

        await performEditorialSync(previous: cached, hasCachedContent: hasCachedContent, force: false)

        didInitialLoad = true
        // Signal ContentView that stores are ready for deep link resolution
        router.contentDidLoad = true
    }

    /// Re-sync editorial content on foreground resume when the cache is stale.
    /// Never blocks; on failure the current content is left untouched.
    private func refreshOnForegroundIfStale() async {
        guard didInitialLoad, !isScreenshotMode else { return }
        let last = UserDefaults.standard.object(forKey: Self.syncDateKey) as? Date ?? .distantPast
        let age = Date().timeIntervalSince(last)
        guard age > Self.foregroundStaleThreshold else {
            NSLog("[EditorialCache] foreground refresh skipped — cache age %.0fs", age)
            return
        }
        NSLog("[EditorialCache] foreground refresh — cache age %.0fs", age)
        await performEditorialSync(previous: nil, hasCachedContent: true, force: false)
    }

    private func replaceStores(with payload: EditorialSyncPayload) {
        store.replace(with: payload.articles)
        eventStore.replace(with: payload.events)
        documentStore.replace(with: payload.documents)
    }

    /// Fetches fresh editorial content (origin, never URLCache), updates the in-memory
    /// stores, and replaces the persisted cache only when the content signature changed.
    /// On fetch failure the cached content remains as a safe fallback.
    private func performEditorialSync(previous: EditorialSyncPayload?, hasCachedContent: Bool, force: Bool) async {
        do {
            let payload = try await coordinator.syncAll()

            // Featured-event reconciliation trace. `cached` is what the banner was showing
            // (restored cache or the previous sync), `remote` is what the backend just
            // said. They differ exactly when an editor changed the flag — and because the
            // store is replaced wholesale, `final` always follows `remote`, including when
            // remote is nil and the banner has to disappear.
            let cachedFeatured = eventStore.featuredEvent?.title
            let remoteFeatured = EventStore.resolveFeatured(from: payload.events)?.title
            replaceStores(with: payload)
            NSLog("[FeaturedEvent] cached=%@", cachedFeatured ?? "nil")
            NSLog("[FeaturedEvent] remote=%@", remoteFeatured ?? "nil")
            NSLog("[FeaturedEvent] final=%@", eventStore.featuredEvent?.title ?? "nil")

            // Recovery net: the store MUST contain every article the payload returned.
            // If any are missing (should never happen now that ArticleDTO decodes
            // resiliently), force a rebuild of both the store and the persisted cache.
            let missing = Set(payload.articles.map(\.id)).subtracting(store.articles.map(\.id))
            if !missing.isEmpty {
                NSLog("[ArticleStore] recovery mismatch — %d payload article(s) missing from store; rebuilding from payload", missing.count)
                store.replace(with: payload.articles)
            }

            let fetchedSignature = payload.contentSignature
            let cachedSignature = UserDefaults.standard.string(forKey: Self.signatureKey)
            let replace = EditorialCachePolicy.shouldReplace(
                fetchedSignature: fetchedSignature,
                cachedSignature: cachedSignature,
                force: force || !missing.isEmpty
            )

            #if DEBUG
            NSLog("[EditorialCache] fetched=%@ cached=%@ → %@ (Grazie!!: %@)",
                  String(fetchedSignature.prefix(12)),
                  cachedSignature.map { String($0.prefix(12)) } ?? "nil",
                  replace ? "REPLACE cache" : "KEEP cache",
                  payload.containsText("Grazie!!") ? "present" : "absent")
            #endif

            if replace {
                try? cache.clearAndReplace(with: payload)
                UserDefaults.standard.set(fetchedSignature, forKey: Self.signatureKey)
            }
            // Record a successful sync even when content was unchanged, so foreground
            // staleness is measured from the last network success, not the last change.
            UserDefaults.standard.set(Date(), forKey: Self.syncDateKey)

            // Schedule notifications for newly detected content (only on launch, when a
            // prior cache existed — skipped on foreground refresh to avoid duplicates).
            if let previous {
                let detected = NewContentDetector.detect(previous: previous, fresh: payload)
                if let a = detected.newArticle  { await LocalNotificationManager.shared.scheduleIfNeeded(for: a) }
                if let e = detected.newEvent    { await LocalNotificationManager.shared.scheduleIfNeeded(for: e) }
                if let d = detected.newDocument { await LocalNotificationManager.shared.scheduleIfNeeded(for: d) }
            }
        } catch {
            NSLog("[EditorialCache] sync failed — keeping cached content: %@", "\(error)")
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
