import Foundation

extension EventDTO {
    func toEvent() -> Event {
        let day      = EventDateParser.dayString(from: dataEvento)
        let month    = EventDateParser.monthShort(from: dataEvento)
        let full     = EventDateParser.fullDate(from: dataEvento)
        let dispTime = ora.trimmingCharacters(in: .whitespaces).isEmpty
                         ? "" : EventDateParser.displayTime(ora)
        let rawDate  = EventDateParser.combinedDate(dateString: dataEvento, timeString: ora)

        #if DEBUG
        if rawDate == nil {
            print("[EventMapper] ⚠️ Date parse failed — title: \(titolo), dataEvento: \(dataEvento), ora: \(ora)")
        }
        #endif

        return Event(
            id:          id,
            title:       titolo,
            slug:        slug,
            type:        tipo,
            day:         day.isEmpty   ? "--"  : day,
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
