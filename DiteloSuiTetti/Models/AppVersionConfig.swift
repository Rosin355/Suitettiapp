import Foundation

/// Remote app-version configuration fetched from the backend `app-config` function.
///
/// Every field is optional so a partial or malformed config never crashes the
/// update check — a missing field simply means "no constraint of that kind".
/// Decoded through the shared `JSONDecoder.editorial` (`.convertFromSnakeCase`),
/// so the JSON keys `latest_ios_version` / `minimum_ios_version` / `app_store_url`
/// map to the camelCase coding keys below.
struct AppVersionConfig: Decodable, Equatable {
    let latestVersion: String?
    let minimumVersion: String?
    let appStoreURL: URL?
    let message: String?

    private enum CodingKeys: String, CodingKey {
        case latestIosVersion   // from latest_ios_version
        case minimumIosVersion  // from minimum_ios_version
        case appStoreUrl        // from app_store_url
        case message
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        latestVersion  = (try? c.decodeIfPresent(String.self, forKey: .latestIosVersion)) ?? nil
        minimumVersion = (try? c.decodeIfPresent(String.self, forKey: .minimumIosVersion)) ?? nil
        message        = (try? c.decodeIfPresent(String.self, forKey: .message)) ?? nil
        let rawURL     = (try? c.decodeIfPresent(String.self, forKey: .appStoreUrl)) ?? nil
        appStoreURL    = rawURL.flatMap { $0.isEmpty ? nil : URL(string: $0) }
    }

    /// Direct initializer for previews, stubs, and tests.
    init(latestVersion: String?, minimumVersion: String?, appStoreURL: URL?, message: String?) {
        self.latestVersion = latestVersion
        self.minimumVersion = minimumVersion
        self.appStoreURL = appStoreURL
        self.message = message
    }
}

/// Lenient semantic-version comparison.
///
/// Tolerates missing components (`"1.0"` == `"1.0.0"`), extra components,
/// pre-release / build metadata suffixes (`"1.0.4-beta"`, `"1.0.4+42"`), and
/// non-numeric noise — it never throws and never traps, so a malformed remote
/// version string can't crash the launch check.
enum SemanticVersion {

    /// `true` when `version` is strictly older than `other`.
    static func isOlder(_ version: String, than other: String) -> Bool {
        compare(version, other) == .orderedAscending
    }

    static func compare(_ a: String, _ b: String) -> ComparisonResult {
        let lhs = components(a)
        let rhs = components(b)
        let count = max(lhs.count, rhs.count)
        for i in 0..<count {
            let x = i < lhs.count ? lhs[i] : 0
            let y = i < rhs.count ? rhs[i] : 0
            if x != y { return x < y ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }

    /// Splits the numeric core (`"1.0.4-beta"` → `[1, 0, 4]`), keeping only digits
    /// per component so stray characters degrade to `0` rather than crashing.
    private static func components(_ raw: String) -> [Int] {
        let core = raw.split(whereSeparator: { $0 == "-" || $0 == "+" })
            .first.map(String.init) ?? raw
        return core.split(separator: ".").map { part in
            Int(part.filter(\.isNumber)) ?? 0
        }
    }
}
