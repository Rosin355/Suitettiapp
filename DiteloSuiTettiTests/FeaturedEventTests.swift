import XCTest
@testable import DiteloSuiTetti

// NOTE: like EditorialCacheTests, these live outside the app's synchronized source
// folder and will run via `xcodebuild test` once a unit-test target is added to the
// project (File ▸ New ▸ Target ▸ Unit Testing Bundle, Host = DiteloSuiTetti).
//
// Covers the QA scenarios for the dynamic featured-event banner: resolution,
// determinism when several events are flagged, decode tolerance, and the
// cache-invalidation rule that stops a cleared flag from resurrecting the banner.
@MainActor
final class FeaturedEventTests: XCTestCase {

    /// One fixed instant per test run so two events built with the same offset get
    /// byte-identical dates and genuinely exercise the later tiebreaks.
    private let now = Date()

    private func makeEvent(
        _ title: String,
        featured: Bool,
        daysFromNow: Double?,
        updatedAt: Date = Date(timeIntervalSince1970: 0),
        id: UUID = UUID()
    ) -> Event {
        Event(
            id: id, title: title, slug: title, type: "evento",
            day: "01", monthShort: "GEN", fullDate: "1 gennaio 2026", time: "",
            location: "Roma", description: "d", link: nil, imageURL: nil,
            rawDate: daysFromNow.map { now.addingTimeInterval(86_400 * $0) },
            updatedAt: updatedAt, syncVersion: 1, isFeatured: featured
        )
    }

    private func decode(_ json: String) throws -> EventDTO {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(EventDTO.self, from: Data(json.utf8))
    }

    private func eventJSON(featured: String?) -> String {
        let flag = featured.map { ",\"is_home_featured\":\($0)" } ?? ""
        return """
        {"id":"11111111-1111-1111-1111-111111111111","titolo":"Evento","slug":"e",
         "tipo":"evento","data_evento":"2026-10-16","ora":null,"luogo":"Roma",
         "descrizione":"d","link":null,"immagine_url":null,
         "updated_at":"2026-08-01T10:00:00Z","sync_version":1\(flag),"attachments":[]}
        """
    }

    // MARK: - Decoding

    func testFeaturedFlagDecodes() throws {
        XCTAssertTrue(try decode(eventJSON(featured: "true")).isFeatured)
        XCTAssertFalse(try decode(eventJSON(featured: "false")).isFeatured)
    }

    /// The field must be optional on the wire: a backend without the column (the state
    /// before the migration is applied) must keep syncing exactly as before.
    func testMissingFlagDecodesToFalseAndKeepsTheEvent() throws {
        let dto = try decode(eventJSON(featured: nil))
        XCTAssertFalse(dto.isFeatured)
        XCTAssertEqual(dto.titolo, "Evento")
    }

    func testNullAndWrongTypeDecodeToFalseWithoutDroppingTheEvent() throws {
        XCTAssertFalse(try decode(eventJSON(featured: "null")).isFeatured)
        let wrongType = try decode(eventJSON(featured: "\"yes\""))
        XCTAssertFalse(wrongType.isFeatured)
        XCTAssertEqual(wrongType.titolo, "Evento", "A wrong-typed flag must never drop the event")
    }

    // MARK: - Resolution (Scenarios A–C)

    func testResolvesTheFlaggedEvent() {
        let featured = makeEvent("Festival", featured: true, daysFromNow: 30)
        let events = [makeEvent("Altro", featured: false, daysFromNow: 10), featured]
        XCTAssertEqual(EventStore.resolveFeatured(from: events)?.id, featured.id)
    }

    func testNothingFlaggedResolvesToNil() {
        XCTAssertNil(EventStore.resolveFeatured(from: []))
        XCTAssertNil(EventStore.resolveFeatured(from: [makeEvent("A", featured: false, daysFromNow: 3)]))
    }

    func testFeaturingADifferentEventSwapsTheWinner() {
        let newWinner = makeEvent("Nuovo", featured: true, daysFromNow: 45)
        let events = [makeEvent("Vecchio", featured: false, daysFromNow: 30), newWinner]
        XCTAssertEqual(EventStore.resolveFeatured(from: events)?.id, newWinner.id)
    }

    /// The backend decides what is promoted — a featured past event still shows.
    func testAPastEventCanBeFeatured() {
        let past = makeEvent("Passato", featured: true, daysFromNow: -5)
        XCTAssertEqual(EventStore.resolveFeatured(from: [past])?.id, past.id)
    }

    // MARK: - Determinism (Scenario F)

    func testMultipleFlaggedEventsResolveDeterministically() {
        let soon = makeEvent("Vicino", featured: true, daysFromNow: 5)
        let candidates = [
            makeEvent("Passato", featured: true, daysFromNow: -10),
            makeEvent("Lontano", featured: true, daysFromNow: 90),
            makeEvent("Senzadata", featured: true, daysFromNow: nil),
            soon,
        ]
        XCTAssertEqual(EventStore.resolveFeatured(from: candidates)?.id, soon.id,
                       "Upcoming beats past/undated, and the nearest upcoming wins")

        for _ in 0..<200 {
            XCTAssertEqual(EventStore.resolveFeatured(from: candidates.shuffled())?.id, soon.id,
                           "Winner must not depend on payload order")
        }
    }

    func testTiesFallThroughToUpdatedAtThenID() {
        let lowID = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!
        let highID = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000002")!
        let older = makeEvent("A", featured: true, daysFromNow: 7,
                              updatedAt: Date(timeIntervalSince1970: 100), id: lowID)
        let newer = makeEvent("B", featured: true, daysFromNow: 7,
                              updatedAt: Date(timeIntervalSince1970: 900), id: highID)
        XCTAssertEqual(EventStore.resolveFeatured(from: [older, newer])?.id, highID,
                       "Same date → newest updatedAt wins")

        let tied = makeEvent("B", featured: true, daysFromNow: 7,
                             updatedAt: Date(timeIntervalSince1970: 100), id: highID)
        for _ in 0..<200 {
            XCTAssertEqual(EventStore.resolveFeatured(from: [older, tied].shuffled())?.id, lowID,
                           "Fully tied → lowest id, so the winner is stable across launches")
        }
    }

    // MARK: - Cache reconciliation (Scenario B / E)

    private func payload(_ events: [Event]) -> EditorialSyncPayload {
        EditorialSyncPayload(articles: [], events: events, documents: [],
                             serverTime: Date(timeIntervalSince1970: 0))
    }

    /// Clearing the flag usually changes nothing else about the event, so the content
    /// signature must react to it — otherwise the persisted cache keeps `isFeatured = true`
    /// and the banner flashes back on the next cold start.
    func testClearingTheFlagInvalidatesTheCache() {
        let id = UUID()
        let on = payload([makeEvent("Festival", featured: true, daysFromNow: 30, id: id)]).contentSignature
        let off = payload([makeEvent("Festival", featured: false, daysFromNow: 30, id: id)]).contentSignature

        XCTAssertNotEqual(on, off, "is_home_featured must participate in the content signature")
        XCTAssertTrue(EditorialCachePolicy.shouldReplace(fetchedSignature: off, cachedSignature: on))
    }

    func testUnchangedPayloadStillKeepsTheCache() {
        let events = [makeEvent("A", featured: false, daysFromNow: 4, id: UUID())]
        let first = payload(events).contentSignature
        let second = payload(events).contentSignature
        XCTAssertFalse(EditorialCachePolicy.shouldReplace(fetchedSignature: second, cachedSignature: first))
    }
}
