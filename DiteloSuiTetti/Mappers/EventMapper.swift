import Foundation

extension EventDTO {
    func toEvent() -> Event {
        let oraValue = ora?.trimmingCharacters(in: .whitespaces) ?? ""
        let day      = EventDateParser.dayString(from: dataEvento)
        let month    = EventDateParser.monthShort(from: dataEvento)
        let full     = EventDateParser.fullDate(from: dataEvento)
        let dispTime = oraValue.isEmpty ? "" : EventDateParser.displayTime(oraValue)
        let rawDate  = EventDateParser.combinedDate(dateString: dataEvento, timeString: oraValue)

        if rawDate == nil {
            NSLog("[EventMapper] ⚠️ date parse failed — title: %@, dataEvento: %@, ora: %@",
                  titolo, dataEvento, oraValue.isEmpty ? "(nil)" : oraValue)
        }

        return Event(
            id:               id,
            title:            titolo,
            slug:             slug,
            type:             tipo,
            day:              day.isEmpty   ? "--"  : day,
            monthShort:       month.isEmpty ? "---" : month,
            fullDate:         full.isEmpty  ? dataEvento : full,
            time:             dispTime,
            location:         luogo,
            description:      descrizione,
            link:             link.flatMap { URL(string: $0) },
            imageURL:         immagineUrl.flatMap { URL(string: $0) },
            rawDate:          rawDate,
            updatedAt:        updatedAt,
            syncVersion:      syncVersion,
            isFeatured:       isFeatured,
            relatedDocuments: attachments
        )
    }
}
