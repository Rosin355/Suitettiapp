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

// MARK: - Mapping

private extension EventDTO {
    func toEvent() -> Event {
        let day        = EventDateParser.dayString(from: dataEvento)
        let month      = EventDateParser.monthShort(from: dataEvento)
        let full       = EventDateParser.fullDate(from: dataEvento)
        let dispTime   = ora.trimmingCharacters(in: .whitespaces).isEmpty
                            ? "" : EventDateParser.displayTime(ora)
        let rawDate    = EventDateParser.combinedDate(dateString: dataEvento, timeString: ora)

        return Event(
            id:          id,
            title:       titolo,
            slug:        slug,
            type:        tipo,
            day:         day.isEmpty   ? "--" : day,
            monthShort:  month.isEmpty ? "---" : month,
            fullDate:    full.isEmpty  ? dataEvento : full,
            time:        dispTime,
            location:    luogo,
            description: descrizione,
            link:        link.flatMap { URL(string: $0) },
            imageURL:    immagineUrl.flatMap { URL(string: $0) },
            rawDate:     rawDate,
            updatedAt:   updatedAt,
            syncVersion: syncVersion
        )
    }
}
