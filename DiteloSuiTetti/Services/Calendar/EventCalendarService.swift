import EventKit

// MARK: - Errors

enum CalendarSaveError: LocalizedError {
    case accessDenied
    case accessRestricted
    case invalidDate
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Accesso al calendario negato. Vai in Impostazioni → Privacy → Calendario."
        case .accessRestricted:
            return "L'accesso al calendario è limitato dalle impostazioni del dispositivo."
        case .invalidDate:
            return "La data dell'evento non è valida e non può essere salvata."
        case .saveFailed(let e):
            return "Impossibile salvare l'evento: \(e.localizedDescription)"
        }
    }
}

// MARK: - Service
//
// Required Info.plist keys (add via Xcode → Target → Info):
//   NSCalendarsFullAccessUsageDescription
//   "Ditelo sui Tetti vuole aggiungere gli eventi al tuo calendario."

@MainActor
final class EventCalendarService {
    static let shared = EventCalendarService()
    private init() {}

    private let store = EKEventStore()

    func saveEvent(_ event: Event) async throws {
        // Request full-access permission (iOS 17+)
        let granted: Bool
        do {
            granted = try await store.requestFullAccessToEvents()
        } catch {
            throw CalendarSaveError.accessDenied
        }
        guard granted else { throw CalendarSaveError.accessDenied }

        guard let startDate = event.rawDate else {
            throw CalendarSaveError.invalidDate
        }

        let ek = EKEvent(eventStore: store)
        ek.title    = event.title
        ek.location = event.location.isEmpty ? nil : event.location
        ek.url      = event.link
        ek.notes    = buildNotes(event)
        ek.calendar = store.defaultCalendarForNewEvents

        let timeIsEmpty = event.time.trimmingCharacters(in: .whitespaces).isEmpty
        if timeIsEmpty {
            ek.isAllDay  = true
            ek.startDate = startDate
            ek.endDate   = startDate
        } else {
            ek.isAllDay  = false
            ek.startDate = startDate
            ek.endDate   = startDate.addingTimeInterval(2 * 3600)   // default 2-hour duration
        }

        do {
            try store.save(ek, span: .thisEvent)
        } catch {
            throw CalendarSaveError.saveFailed(error)
        }
    }

    private func buildNotes(_ event: Event) -> String? {
        var parts: [String] = []
        let plain = HTMLTextFormatter.plainText(from: event.description)
        if !plain.isEmpty { parts.append(plain) }
        if let link = event.link { parts.append("Scopri di più: \(link.absoluteString)") }
        return parts.isEmpty ? nil : parts.joined(separator: "\n\n")
    }
}
