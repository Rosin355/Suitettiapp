import Foundation

@MainActor
@Observable
final class EventStore {

    private(set) var events: [Event] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?
    private(set) var offlineMessage: String?

    var upcomingEvents: [Event] {
        events
            .filter { $0.isUpcoming }
            .sorted { ($0.rawDate ?? .distantFuture) < ($1.rawDate ?? .distantFuture) }
    }

    var pastEvents: [Event] {
        events
            .filter { $0.isPast }
            .sorted { ($0.rawDate ?? .distantPast) > ($1.rawDate ?? .distantPast) }
    }

    var undatedEvents: [Event] {
        events.filter { $0.isUndated }
    }

    // MARK: - Featured event

    /// The event the CMS is currently promoting, or nil when nothing is featured.
    ///
    /// Derived from `events` on every read, never stored: the Home banner therefore
    /// appears, changes and disappears purely as a consequence of what the last sync
    /// returned. There is deliberately no separate persisted "banner" state to go stale.
    var featuredEvent: Event? {
        Self.resolveFeatured(from: events)
    }

    /// Picks the single winner among the events flagged `is_featured` by the backend.
    ///
    /// Static so the sync layer can resolve the *incoming* payload's winner for
    /// diagnostics before the store is replaced.
    static func resolveFeatured(from events: [Event]) -> Event? {
        let featured = events.filter(\.isFeatured)
        guard featured.count > 1 else { return featured.first }

        // The admin enforces exclusivity, so more than one winner means the data was
        // edited outside that path. Pick deterministically and carry on rather than
        // letting the banner flicker between candidates on successive syncs.
        NSLog("[FeaturedEvent] ⚠️ %d events flagged featured — resolving deterministically: %@",
              featured.count, featured.map(\.title).joined(separator: " | "))
        return featured.min(by: isPreferredFeatured)
    }

    /// Total ordering over featured candidates: upcoming first, then nearest by event
    /// date, then most recently updated, then id. The final id tiebreak is what makes
    /// this deterministic — without it two otherwise-identical events could swap places
    /// between launches.
    private static func isPreferredFeatured(_ a: Event, _ b: Event) -> Bool {
        // 1. an upcoming event always beats a past or undated one
        if a.isUpcoming != b.isUpcoming { return a.isUpcoming }

        // 2. nearest event date — soonest first when upcoming, most recent first otherwise.
        //    A dated event always beats an undated one.
        switch (a.rawDate, b.rawDate) {
        case let (date1?, date2?) where date1 != date2:
            return a.isUpcoming ? date1 < date2 : date1 > date2
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            break
        }

        // 3. newest updatedAt
        let updatedA = a.updatedAt ?? .distantPast
        let updatedB = b.updatedAt ?? .distantPast
        if updatedA != updatedB { return updatedA > updatedB }

        // 4. stable final tiebreak
        return a.id.uuidString < b.id.uuidString
    }

    private let service: any EventServiceProtocol

    init(service: any EventServiceProtocol = LiveEventService()) {
        self.service = service
    }

    func load() async {
        guard !isLoading, !isRefreshing, events.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            events = try await service.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard !isLoading, !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }
        do {
            events = try await service.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Coordinator support

    func beginLoading() {
        guard !isLoading, !isRefreshing else { return }
        isLoading = true
        errorMessage = nil
    }

    func replace(with events: [Event]) {
        self.events = events
        isLoading = false
        isRefreshing = false
        offlineMessage = nil
    }

    func failedLoading(message: String) {
        errorMessage = message
        isLoading = false
        isRefreshing = false
    }

    func setOfflineWarning() {
        offlineMessage = "Contenuto non aggiornato — verifica la connessione."
    }
}
