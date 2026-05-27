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

    static var syncEditorialEndpoint: URL {
        apiBaseURL.appendingPathComponent("functions/v1/sync-editorial")
    }

    static var registerPushTokenEndpoint: URL {
        apiBaseURL.appendingPathComponent("functions/v1/register-push-token")
    }

    static func syncEditorialDeltaEndpoint(since date: Date) -> URL {
        var components = URLComponents(url: syncEditorialEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "since", value: ISO8601DateFormatter().string(from: date))
        ]
        return components.url!
    }
}
