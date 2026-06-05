import Foundation

@MainActor
final class PushTokenRegistrationService {
    static let shared = PushTokenRegistrationService()
    private init() {}

    private let lastTokenKey = "lastRegisteredPushToken"

    func register(deviceToken: String) async {
        let previous = UserDefaults.standard.string(forKey: lastTokenKey)
        guard deviceToken != previous else {
            NSLog("[PushTokenRegistrationService] ↩ token unchanged — skipping registration")
            return
        }

        // TestFlight and App Store builds are Release → "production".
        // Simulator and direct Xcode runs are Debug → "sandbox".
        let environment: String
        #if DEBUG
        environment = "sandbox"
        #else
        environment = "production"
        #endif

        let payload: [String: Any] = [
            "deviceToken": deviceToken,
            "platform": "ios",
            "environment": environment,
            "bundleId": Bundle.main.bundleIdentifier ?? "",
            "appVersion": (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "",
            "buildNumber": (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? ""
        ]

        NSLog("[PushTokenRegistrationService] ▶ registering — prefix: %@… env: %@",
              String(deviceToken.prefix(8)), environment)

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            NSLog("[PushTokenRegistrationService] ✗ JSON serialization failed")
            return
        }

        var request = URLRequest(url: AppEnvironment.registerPushTokenEndpoint, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DiteloSuiTetti-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = body

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                NSLog("[PushTokenRegistrationService] ✗ unexpected response type")
                return
            }
            if (200..<300).contains(http.statusCode) {
                UserDefaults.standard.set(deviceToken, forKey: lastTokenKey)
                NSLog("[PushTokenRegistrationService] ✓ registered (HTTP %d)", http.statusCode)
            } else {
                NSLog("[PushTokenRegistrationService] ✗ server rejected — HTTP %d", http.statusCode)
            }
        } catch {
            NSLog("[PushTokenRegistrationService] ✗ network error — %@", error.localizedDescription)
        }
    }
}
