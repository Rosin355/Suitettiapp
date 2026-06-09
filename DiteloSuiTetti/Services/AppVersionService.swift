import Foundation

// MARK: - Protocol

protocol AppVersionServiceProtocol: Sendable {
    /// Fetches the remote app-version config. Throws on transport/decode failure;
    /// the caller (AppVersionStore) treats any error as "no update info" and never blocks.
    func fetchConfig() async throws -> AppVersionConfig
}

// MARK: - Stub (previews / tests)

struct StubAppVersionService: AppVersionServiceProtocol {
    var config: AppVersionConfig = AppVersionConfig(
        latestVersion: "1.0.4",
        minimumVersion: "1.0.2",
        appStoreURL: URL(string: "https://apps.apple.com/app/id000000000"),
        message: "È disponibile una nuova versione di Ditelo sui Tetti."
    )
    func fetchConfig() async throws -> AppVersionConfig { config }
}

// MARK: - Live

struct LiveAppVersionService: AppVersionServiceProtocol {
    func fetchConfig() async throws -> AppVersionConfig {
        try await APIClient.fetch(AppEnvironment.appConfigEndpoint)
    }
}
