import Foundation

struct Event: Identifiable {
    let id: UUID
    let title: String
    let slug: String
    let type: String
    let day: String         // "07"
    let monthShort: String  // "GIU"
    let fullDate: String    // "7 giugno 2026"
    let time: String        // "10:00" or ""
    let location: String
    let description: String
    let link: URL?
    let imageURL: URL?
    let rawDate: Date?      // parsed start date, used for calendar
    let updatedAt: Date
    let syncVersion: Int

    var isUpcoming: Bool {
        guard let raw = rawDate else { return true }
        return raw >= Calendar.current.startOfDay(for: Date())
    }
}
