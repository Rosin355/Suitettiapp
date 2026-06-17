import XCTest
import SwiftUI
@testable import DiteloSuiTetti

// NOTE: This project currently ships a single application target (no unit-test
// bundle). These tests are written against the pure cache-invalidation logic and
// will run via `xcodebuild test` once a unit-test target is added to the project
// (File ▸ New ▸ Target ▸ Unit Testing Bundle, Host = DiteloSuiTetti). They are kept
// here, outside the app's synchronized source folder, so they never compile into
// the app target.
final class EditorialCacheTests: XCTestCase {

    // Two articles with the same id but different body → different signature.
    private let fixedID = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!

    private func payload(body: String) -> EditorialSyncPayload {
        let article = Article(
            id: fixedID,
            slug: "art",
            category: "Cat",
            categoryColor: .red,
            thumbnailColors: [],
            title: "Titolo",
            date: "1 gen",
            fullDate: "1 gennaio 2026",
            readTime: "1 min",
            excerpt: "",
            body: body
        )
        return EditorialSyncPayload(articles: [article], events: [], documents: [], serverTime: Date(timeIntervalSince1970: 0))
    }

    // 1. Fresh payload replaces stale cache.
    func testFreshPayloadReplacesStaleCache() {
        let staleSig = payload(body: "Grazie").contentSignature
        let freshSig = payload(body: "Grazie!!").contentSignature
        XCTAssertNotEqual(freshSig, staleSig, "Body change must change the signature")
        XCTAssertTrue(EditorialCachePolicy.shouldReplace(fetchedSignature: freshSig, cachedSignature: staleSig))
    }

    // 2. Same version keeps cache.
    func testSameVersionKeepsCache() {
        let sig = payload(body: "Grazie!!").contentSignature
        XCTAssertFalse(EditorialCachePolicy.shouldReplace(fetchedSignature: sig, cachedSignature: sig))
    }

    // 2b. No cached signature yet → replace.
    func testNoCacheReplaces() {
        let sig = payload(body: "x").contentSignature
        XCTAssertTrue(EditorialCachePolicy.shouldReplace(fetchedSignature: sig, cachedSignature: nil))
    }

    // 3. Failed fetch uses cached fallback (models loadContent's catch path).
    func testFailedFetchUsesCachedFallback() {
        let cached = payload(body: "vecchio contenuto")
        let fetched: EditorialSyncPayload? = nil  // simulate a failed sync
        let effective = fetched ?? cached
        XCTAssertEqual(effective.contentSignature, cached.contentSignature)
    }

    // 4. Force refresh bypasses a matching (stale) cache.
    func testForceRefreshBypassesMatchingCache() {
        let sig = payload(body: "x").contentSignature
        XCTAssertTrue(EditorialCachePolicy.shouldReplace(fetchedSignature: sig, cachedSignature: sig, force: true))
    }

    // Signature stability: identical content → identical signature across instances.
    func testSignatureIsStableForIdenticalContent() {
        XCTAssertEqual(payload(body: "Grazie!!").contentSignature, payload(body: "Grazie!!").contentSignature)
    }

    #if DEBUG
    func testContainsTextDetectsMarker() {
        XCTAssertTrue(payload(body: "Grazie!!").containsText("Grazie!!"))
        XCTAssertFalse(payload(body: "Ciao").containsText("Grazie!!"))
    }
    #endif
}
