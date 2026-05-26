import SwiftData
import Foundation

@Model
final class CachedEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var slug: String
    var type: String
    var day: String
    var monthShort: String
    var fullDate: String
    var time: String
    var location: String
    var eventDescription: String
    var linkString: String?
    var imageURLString: String?
    var rawDate: Date?
    var updatedAt: Date
    var syncVersion: Int

    init(from event: Event) {
        id               = event.id
        title            = event.title
        slug             = event.slug
        type             = event.type
        day              = event.day
        monthShort       = event.monthShort
        fullDate         = event.fullDate
        time             = event.time
        location         = event.location
        eventDescription = event.description
        linkString       = event.link?.absoluteString
        imageURLString   = event.imageURL?.absoluteString
        rawDate          = event.rawDate
        updatedAt        = event.updatedAt
        syncVersion      = event.syncVersion
    }

    func toEvent() -> Event {
        Event(
            id:          id,
            title:       title,
            slug:        slug,
            type:        type,
            day:         day,
            monthShort:  monthShort,
            fullDate:    fullDate,
            time:        time,
            location:    location,
            description: eventDescription,
            link:        linkString.flatMap { URL(string: $0) },
            imageURL:    imageURLString.flatMap { URL(string: $0) },
            rawDate:     rawDate,
            updatedAt:   updatedAt,
            syncVersion: syncVersion
        )
    }
}
