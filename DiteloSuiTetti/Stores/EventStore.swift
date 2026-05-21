import Foundation

@MainActor
@Observable
final class EventStore {

    private(set) var events: [Event] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?

    var upcomingEvents: [Event] {
        events
            .filter { $0.isUpcoming }
            .sorted { ($0.rawDate ?? .distantFuture) < ($1.rawDate ?? .distantFuture) }
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
}
