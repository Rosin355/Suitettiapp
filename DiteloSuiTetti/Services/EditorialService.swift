import Foundation
import SwiftUI

// MARK: - Protocol

protocol EditorialServiceProtocol: Sendable {
    func fetchAll() async throws -> [Article]
    func fetchDelta(since date: Date) async throws -> [Article]
}

// MARK: - Stub (previews)

struct StubEditorialService: EditorialServiceProtocol {
    func fetchAll() async throws -> [Article] { Article.all }
    func fetchDelta(since date: Date) async throws -> [Article] { [] }
}

// MARK: - Live

struct LiveEditorialService: EditorialServiceProtocol {
    func fetchAll() async throws -> [Article] {
        let response: EditorialSyncResponseDTO = try await APIClient.fetch(AppEnvironment.syncEditorialEndpoint)
        return response.articles.map { $0.toArticle() }
    }

    func fetchDelta(since date: Date) async throws -> [Article] {
        let response: EditorialSyncResponseDTO = try await APIClient.fetch(
            AppEnvironment.syncEditorialDeltaEndpoint(since: date)
        )
        return response.articles.map { $0.toArticle() }
    }
}

// MARK: - Mapping

private let articlePalette: [(Color, [Color])] = [
    (.brandRed,
     [Color(red: 253/255, green: 224/255, blue: 224/255),
      Color(red: 245/255, green: 188/255, blue: 188/255)]),
    (Color(red: 42/255, green: 122/255, blue: 75/255),
     [Color(red: 212/255, green: 240/255, blue: 224/255),
      Color(red: 158/255, green: 212/255, blue: 180/255)]),
    (Color(red: 91/255, green: 82/255, blue: 208/255),
     [Color(red: 220/255, green: 216/255, blue: 245/255),
      Color(red: 184/255, green: 177/255, blue: 232/255)]),
    (Color(red: 192/255, green: 112/255, blue: 32/255),
     [Color(red: 252/255, green: 239/255, blue: 170/255),
      Color(red: 240/255, green: 216/255, blue: 64/255)]),
    (Color(red: 38/255, green: 138/255, blue: 188/255),
     [Color(red: 212/255, green: 232/255, blue: 248/255),
      Color(red: 158/255, green: 208/255, blue: 236/255)]),
]

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

private extension ArticleDTO {
    func toArticle() -> Article {
        let index = Int(id.uuid.0) % articlePalette.count
        let (categoryColor, thumbnailColors) = articlePalette[index]
        let bodyWords = contenuto.split(separator: " ").count
        let readMinutes = max(1, Int(ceil(Double(bodyWords) / 200.0)))
        return Article(
            id: id,
            slug: slug,
            category: categoria,
            categoryColor: categoryColor,
            thumbnailColors: thumbnailColors,
            title: sentenceCase(titolo),
            date: shortDateFormatter.string(from: dataPubblicazione),
            fullDate: fullDateFormatter.string(from: dataPubblicazione),
            readTime: "\(readMinutes) min",
            excerpt: estratto,
            body: contenuto,
            imageURL: immagineUrl.flatMap { URL(string: $0) }
        )
    }
}
