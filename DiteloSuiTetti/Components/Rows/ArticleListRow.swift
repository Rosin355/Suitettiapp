import SwiftUI

struct ArticleListRow: View {
    let article: Article
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                RemoteImageView(url: article.imageURL, fallbackColors: article.thumbnailColors)
                    .frame(width: 58, height: 58)
                    .clipShape(.rect(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    CategoryChip(text: article.category, color: article.categoryColor,
                                 background: article.categoryColor.opacity(0.13))

                    Text(article.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.brandBlack)
                        .lineLimit(2)
                        .kerning(-0.25)

                    HStack(spacing: 5) {
                        Text(article.fullDate)
                        Circle().frame(width: 2.5, height: 2.5).foregroundStyle(.brandGray)
                        Text(article.readTime)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.brandGray)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(article.category). \(article.title). \(article.fullDate), \(article.readTime) di lettura.")

            if !isLast {
                Divider().padding(.leading, 88)
            }
        }
    }
}
