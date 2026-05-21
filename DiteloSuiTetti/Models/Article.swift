import SwiftUI

struct Article: Identifiable {
    let id: UUID
    let slug: String
    let category: String
    let categoryColor: Color
    let thumbnailColors: [Color]
    let title: String
    let date: String
    let fullDate: String
    let readTime: String
    let excerpt: String
    let imageURL: URL?

    init(
        id: UUID = UUID(),
        slug: String = "",
        category: String,
        categoryColor: Color,
        thumbnailColors: [Color],
        title: String,
        date: String,
        fullDate: String,
        readTime: String,
        excerpt: String = "",
        imageURL: URL? = nil
    ) {
        self.id = id
        self.slug = slug
        self.category = category
        self.categoryColor = categoryColor
        self.thumbnailColors = thumbnailColors
        self.title = title
        self.date = date
        self.fullDate = fullDate
        self.readTime = readTime
        self.excerpt = excerpt
        self.imageURL = imageURL
    }
}
