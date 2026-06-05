import SwiftData
import SwiftUI

@Model
final class CachedArticle {
    @Attribute(.unique) var id: UUID
    var slug: String
    var category: String
    var title: String
    var date: String
    var fullDate: String
    var readTime: String
    var excerpt: String
    var body: String
    var imageURLString: String?
    var relatedDocumentsJSON: String?

    init(from article: Article) {
        id             = article.id
        slug           = article.slug
        category       = article.category
        title          = article.title
        date           = article.date
        fullDate       = article.fullDate
        readTime       = article.readTime
        excerpt        = article.excerpt
        body           = article.body
        imageURLString = article.imageURL?.absoluteString
        relatedDocumentsJSON = article.relatedDocuments.isEmpty ? nil :
            (try? JSONEncoder().encode(article.relatedDocuments)).flatMap { String(data: $0, encoding: .utf8) }
    }

    func toArticle() -> Article {
        let index = Int(id.uuid.0) % articleColorPalette.count
        let (categoryColor, thumbnailColors) = articleColorPalette[index]
        let relatedDocuments: [RelatedDocument] = relatedDocumentsJSON
            .flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONDecoder().decode([RelatedDocument].self, from: $0) } ?? []
        return Article(
            id:               id,
            slug:             slug,
            category:         category,
            categoryColor:    categoryColor,
            thumbnailColors:  thumbnailColors,
            title:            title,
            date:             date,
            fullDate:         fullDate,
            readTime:         readTime,
            excerpt:          excerpt,
            body:             body,
            imageURL:         imageURLString.flatMap { URL(string: $0) },
            relatedDocuments: relatedDocuments
        )
    }
}
