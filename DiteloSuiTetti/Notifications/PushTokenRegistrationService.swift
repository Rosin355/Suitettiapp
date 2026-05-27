import Foundation

@MainActor
final class PushTokenRegistrationService {
    static let shared = PushTokenRegistrationService()
    private init() {}

    private let lastTokenKey = "lastRegisteredPushToken"

    func register(deviceToken: String) async {
        let previous = UserDefaults.standard.string(forKey: lastTokenKey)
        guard deviceToken != previous else { return }

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

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: AppEnvironment.registerPushTokenEndpoint, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DiteloSuiTetti-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = body

        #if DEBUG
        print("[PushTokenRegistrationService] ▶ registering token prefix: \(String(deviceToken.prefix(8)))…")
        #endif

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            if (200..<300).contains(http.statusCode) {
                UserDefaults.standard.set(deviceToken, forKey: lastTokenKey)
                #if DEBUG
                print("[PushTokenRegistrationService] ✓ token registered (HTTP \(http.statusCode))")
                #endif
            } else {
                #if DEBUG
                print("[PushTokenRegistrationService] ✗ registration failed — HTTP \(http.statusCode)")
                #endif
            }
        } catch {
            #if DEBUG
            print("[PushTokenRegistrationService] ✗ registration error — \(error.localizedDescription)")
            #endif
        }
    }
}
