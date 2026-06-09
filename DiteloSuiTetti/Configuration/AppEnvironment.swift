import Foundation

/// Central source of truth for all environment-specific values.
///
/// Current behaviour: values are resolved from Bundle.main.infoDictionary when
/// present (xcconfig → Info.plist pipeline), falling back to known defaults so
/// the app compiles and runs before Xcode build configurations are wired up.
///
/// How to wire xcconfig:
/// 1. Xcode → Project → Info → Configurations → assign Config/Debug.xcconfig and
///    Config/Release.xcconfig to their respective configurations.
/// 2. Add keys to Info.plist:  API_BASE_URL → $(API_BASE_URL)
///                              WEBSITE_URL  → $(WEBSITE_URL)
/// 3. The fallback strings below become dead code and can be removed.
enum AppEnvironment {

    // MARK: - Base URLs

    static let apiBaseURL: URL = {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://kbswgeliohnpwopzzzpc.supabase.co")!
    }()

    static let websiteURL: URL = {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "WEBSITE_URL") as? String,
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://comitaticivici.it")!
    }()

    // MARK: - Endpoints

    static var privacyPolicyURL: URL { websiteURL.appendingPathComponent("privacy") }
    static var termsURL: URL        { websiteURL.appendingPathComponent("termini") }

    static let digitalYoginURL = URL(string: "https://www.digitalyogin.com")!

    // MARK: - Public canonical domain (sharing)

    /// Canonical public website used for all shareable content links.
    /// This is the user-facing domain — never share legacy/preview domains
    /// (comitaticivici.it, *.lovable.app, etc.).
    static let publicWebsiteURL = URL(string: "https://www.suitetti.org")!

    /// Public App Store listing, appended to share messages.
    static let appStoreURL = URL(string: "https://apps.apple.com/it/app/suitetti/id6772963310")!

    /// Canonical share URLs: https://www.suitetti.org/{articoli|eventi|documenti}/{slug}
    static func articleShareURL(slug: String) -> URL {
        publicWebsiteURL.appendingPathComponent("articoli").appendingPathComponent(slug)
    }
    static func eventShareURL(slug: String) -> URL {
        publicWebsiteURL.appendingPathComponent("eventi").appendingPathComponent(slug)
    }
    static func documentShareURL(slug: String) -> URL {
        publicWebsiteURL.appendingPathComponent("documenti").appendingPathComponent(slug)
    }

    // MARK: - Support

    static let supportEmail = "info@digitalyogin.com"

    // MARK: - Endpoints

    static var syncEditorialEndpoint: URL {
        apiBaseURL.appendingPathComponent("functions/v1/sync-editorial")
    }

    static var registerPushTokenEndpoint: URL {
        apiBaseURL.appendingPathComponent("functions/v1/register-push-token")
    }

    /// Remote app-version config (latest/minimum iOS version, App Store URL, message).
    /// Backend endpoint to be deployed; see docs/API_CONTRACT.md "App Version Config".
    static var appConfigEndpoint: URL {
        apiBaseURL.appendingPathComponent("functions/v1/app-config")
    }

    static func syncEditorialDeltaEndpoint(since date: Date) -> URL {
        var components = URLComponents(url: syncEditorialEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "since", value: ISO8601DateFormatter().string(from: date))
        ]
        return components.url!
    }
}
