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
            id:               id,
            slug:             slug,
            category:         categoria,
            categoryColor:    categoryColor,
            thumbnailColors:  thumbnailColors,
            title:            sentenceCase(titolo),
            date:             dateShort,
            fullDate:         dateFull,
            publishedAt:      dataPubblicazione,
            readTime:         "\(readMinutes) min",
            excerpt:          estratto,
            body:             contenuto,
            imageURL:         ArticleDTO.parseImageURL(immagineUrl, slug: slug),
            relatedDocuments: attachments
        )
    }

    /// Parses the image URL string, with a percent-encoding fallback for URLs
    /// that contain spaces or non-ASCII characters (common in Italian filenames).
    private static func parseImageURL(_ raw: String?, slug: String) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        if let url = URL(string: raw) { return url }
        // Fallback: percent-encode characters that are invalid in URL strings
        if let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encoded) {
            NSLog("[ArticleMapper] ⚠️ imageURL needed percent-encoding for slug '%@'", slug)
            return url
        }
        NSLog("[ArticleMapper] ✗ imageURL unparseable for slug '%@': %@", slug, raw)
        return nil
    }
}
