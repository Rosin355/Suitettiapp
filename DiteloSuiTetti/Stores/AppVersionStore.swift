import SwiftUI
import UIKit

/// What kind of update prompt (if any) the user should see this launch.
enum AppUpdateRequirement: Equatable {
    case none
    case soft(AppVersionConfig)    // newer version available — dismissible
    case forced(AppVersionConfig)  // below minimum — blocking, no dismiss

    var config: AppVersionConfig? {
        switch self {
        case .none:                return nil
        case .soft(let c),
             .forced(let c):       return c
        }
    }

    var isForced: Bool {
        if case .forced = self { return true }
        return false
    }
}

/// Drives the in-app update prompt from backend remote config.
///
/// - Reads the running version from `CFBundleShortVersionString`.
/// - `current < minimum_ios_version` → blocking `.forced` prompt.
/// - `current < latest_ios_version`  → dismissible `.soft` prompt (unless that
///   exact latest version was already dismissed).
/// - Any config-fetch failure is logged and ignored — the app is never blocked.
@MainActor
@Observable
final class AppVersionStore {

    private(set) var requirement: AppUpdateRequirement = .none

    private let service: any AppVersionServiceProtocol
    private static let dismissedKey = "dismissedSoftUpdateVersion"

    init(service: any AppVersionServiceProtocol = LiveAppVersionService()) {
        self.service = service
    }

    /// Current marketing version, e.g. "1.0.3". Defaults to "0.0.0" if absent.
    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    // MARK: - Launch check

    func check() async {
        let current = Self.currentVersion
        NSLog("[AppVersionStore] checking — current version %@", current)
        do {
            let config = try await service.fetchConfig()
            NSLog("[AppVersionStore] config — latest: %@, minimum: %@, url: %@",
                  config.latestVersion ?? "nil",
                  config.minimumVersion ?? "nil",
                  config.appStoreURL?.absoluteString ?? "nil")
            evaluate(config, current: current)
        } catch {
            // Never block the app on a config failure.
            NSLog("[AppVersionStore] ✗ config fetch failed — ignoring, app not blocked: %@", "\(error)")
            requirement = .none
        }
    }

    private func evaluate(_ config: AppVersionConfig, current: String) {
        if let minimum = config.minimumVersion, SemanticVersion.isOlder(current, than: minimum) {
            NSLog("[AppVersionStore] FORCED update — current %@ < minimum %@", current, minimum)
            requirement = .forced(config)
            return
        }

        if let latest = config.latestVersion, SemanticVersion.isOlder(current, than: latest) {
            let dismissed = UserDefaults.standard.string(forKey: Self.dismissedKey)
            if dismissed == latest {
                NSLog("[AppVersionStore] soft update %@ already dismissed — not showing", latest)
                requirement = .none
                return
            }
            NSLog("[AppVersionStore] SOFT update — current %@ < latest %@", current, latest)
            requirement = .soft(config)
            return
        }

        NSLog("[AppVersionStore] up to date — current %@", current)
        requirement = .none
    }

    // MARK: - User actions

    /// Opens the App Store listing from the config. No-op (logged) if absent.
    func openAppStore() {
        guard let url = requirement.config?.appStoreURL else {
            NSLog("[AppVersionStore] ✗ openAppStore — no app_store_url in config")
            return
        }
        NSLog("[AppVersionStore] opening App Store: %@", url.absoluteString)
        UIApplication.shared.open(url)
    }

    /// Dismisses the soft prompt and remembers the latest version so it does not
    /// reappear on every launch for the same release. No effect on forced prompts.
    func dismissSoftUpdate() {
        guard case let .soft(config) = requirement else { return }
        if let latest = config.latestVersion {
            UserDefaults.standard.set(latest, forKey: Self.dismissedKey)
            NSLog("[AppVersionStore] soft update %@ dismissed — won't show again for this version", latest)
        }
        requirement = .none
    }
}
