import SwiftUI

private let shortDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "it_IT")
    f.dateFormat = "d MMM"
    return f
}()

private let fullDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "it_IT")
    f.dateFormat = "d MMM yyyy"
    return f
}()

private func sentenceCase(_ raw: String) -> String {
    guard !raw.isEmpty, raw == raw.uppercased() else { return raw }
    let lower = raw.lowercased()
    return lower.prefix(1).uppercased() + lower.dropFirst()
}

extension ArticleDTO {
    func toArticle() -> Article {
        let index = Int(id.uuid.0) % articleColorPalette.count
        let (categoryColor, thumbnailColors) = articleColorPalette[index]
        let bodyWords = contenuto.split(separator: " ").count
        let readMinutes = max(1, Int(ceil(Double(bodyWords) / 200.0)))
        let dateShort = dataPubblicazione.map { shortDateFormatter.string(from: $0) } ?? "Data non disponibile"
        let dateFull  = dataPubblicazione.map { fullDateFormatter.string(from: $0)  } ?? "Data non disponibile"
        return Article(
            id:              id,
            slug:            slug,
            category:        categoria,
            categoryColor:   categoryColor,
            thumbnailColors: thumbnailColors,
            title:           sentenceCase(titolo),
            date:            dateShort,
            fullDate:        dateFull,
            readTime:        "\(readMinutes) min",
            excerpt:         estratto,
            body:            contenuto,
            imageURL:        immagineUrl.flatMap { URL(string: $0) }
        )
    }
}
