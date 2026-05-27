import SwiftUI
import UIKit

@main
struct DiteloSuiTettiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var store         = ArticleStore()
    @State private var eventStore    = EventStore()
    @State private var documentStore = DocumentStore()
    @State private var cache         = EditorialCacheRepository()
    @State private var router        = AppDeepLinkRouter.shared
    private let coordinator          = EditorialSyncCoordinator()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding      = false
    @State private var showNotificationPrompt                             = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasSeenOnboarding {
                    ContentView()
                        .environment(store)
                        .environment(eventStore)
                        .environment(documentStore)
                        .environment(router)
                        .task { await loadContent() }
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
        let notifStatus = await LocalNotificationManager.shared.authorizationStatus()
        if notifStatus == .authorized || notifStatus == .provisional || notifStatus == .ephemeral {
            UIApplication.shared.registerForRemoteNotifications()
        }

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

            // Schedule notifications for newly detected content (only when cache existed before)
            if let previous = cached {
                let detected = NewContentDetector.detect(previous: previous, fresh: payload)
                if let a = detected.newArticle  { await LocalNotificationManager.shared.scheduleIfNeeded(for: a) }
                if let e = detected.newEvent    { await LocalNotificationManager.shared.scheduleIfNeeded(for: e) }
                if let d = detected.newDocument { await LocalNotificationManager.shared.scheduleIfNeeded(for: d) }
            }
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

        // Signal ContentView that stores are ready for deep link resolution
        router.contentDidLoad = true
    }
}
