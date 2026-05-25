import Foundation

// MARK: - Protocol

protocol EventServiceProtocol: Sendable {
    func fetchAll() async throws -> [Event]
}

// MARK: - Stub (previews)

struct StubEventService: EventServiceProtocol {
    func fetchAll() async throws -> [Event] { Event.all }
}

// MARK: - Live

struct LiveEventService: EventServiceProtocol {
    func fetchAll() async throws -> [Event] {
        let response: EditorialSyncResponseDTO = try await APIClient.fetch(AppEnvironment.syncEditorialEndpoint)
        return response.events.map { $0.toEvent() }
    }
}
