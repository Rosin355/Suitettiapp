import Foundation
import CryptoKit

/// Decides whether a freshly fetched editorial payload should replace the
/// persisted (SwiftData) cache, based on a stable content signature.
enum EditorialCachePolicy {

    /// Replace the cache when forced, when nothing is cached yet, or when the
    /// fetched content signature differs from the cached one. When the signature
    /// is unchanged the existing cache is kept (no redundant rewrite).
    static func shouldReplace(fetchedSignature: String, cachedSignature: String?, force: Bool = false) -> Bool {
        force || cachedSignature == nil || fetchedSignature != cachedSignature
    }
}

extension EditorialSyncPayload {

    /// Stable, cross-launch hash of the user-visible editorial text. Any change to a
    /// title/excerpt/body/description (e.g. the backend now serving `"Grazie!!"`)
    /// changes this signature, which is how we know to invalidate the local cache.
    ///
    /// Uses SHA-256 because Swift's `Hasher` is seeded per launch and therefore
    /// useless for a value persisted in `UserDefaults` and compared across launches.
    var contentSignature: String {
        var sha = SHA256()
        func feed(_ string: String) {
            sha.update(data: Data(string.utf8))
            sha.update(data: Data([0]))  // delimiter so "ab"+"c" ≠ "a"+"bc"
        }
        for a in articles  { feed(a.id.uuidString); feed(a.title); feed(a.excerpt); feed(a.body) }
        for e in events    { feed(e.id.uuidString); feed(e.title); feed(e.description) }
        for d in documents { feed(d.id.uuidString); feed(d.title); feed(d.description) }
        return sha.finalize().map { String(format: "%02x", $0) }.joined()
    }

    #if DEBUG
    /// DEBUG-only: is `needle` present anywhere in the payload's visible text?
    /// Used to log whether a marker string (e.g. `"Grazie!!"`) reached the device.
    func containsText(_ needle: String) -> Bool {
        articles.contains  { $0.title.contains(needle) || $0.excerpt.contains(needle) || $0.body.contains(needle) }
        || events.contains { $0.title.contains(needle) || $0.description.contains(needle) }
        || documents.contains { $0.title.contains(needle) || $0.description.contains(needle) }
    }
    #endif
}
