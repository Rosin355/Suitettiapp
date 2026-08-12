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
    let updatedAt: Date?
    let syncVersion: Int
    /// Promoted to the Home featured banner by the CMS (`events.is_featured`).
    /// Defaults to false everywhere so a backend or cache without the field is
    /// simply "nothing featured", never a crash and never a stale banner.
    let isFeatured: Bool
    let relatedDocuments: [RelatedDocument]

    // Custom init required because relatedDocuments must default to [] while
    // keeping all other properties non-optional without synthesized init ambiguity.
    init(
        id: UUID,
        title: String,
        slug: String,
        type: String,
        day: String,
        monthShort: String,
        fullDate: String,
        time: String,
        location: String,
        description: String,
        link: URL?,
        imageURL: URL?,
        rawDate: Date?,
        updatedAt: Date?,
        syncVersion: Int,
        isFeatured: Bool = false,
        relatedDocuments: [RelatedDocument] = []
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.type = type
        self.day = day
        self.monthShort = monthShort
        self.fullDate = fullDate
        self.time = time
        self.location = location
        self.description = description
        self.link = link
        self.imageURL = imageURL
        self.rawDate = rawDate
        self.updatedAt = updatedAt
        self.syncVersion = syncVersion
        self.isFeatured = isFeatured
        self.relatedDocuments = relatedDocuments
    }

    var isUpcoming: Bool {
        guard let raw = rawDate else { return false }
        return raw >= Calendar.current.startOfDay(for: Date())
    }

    var isPast: Bool {
        guard let raw = rawDate else { return false }
        return raw < Calendar.current.startOfDay(for: Date())
    }

    var isUndated: Bool { rawDate == nil }
}
