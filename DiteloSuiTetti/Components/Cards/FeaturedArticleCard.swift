import SwiftUI

struct FeaturedArticleCard: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: article.thumbnailColors,
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 108)

                CategoryChip(text: article.category, color: article.categoryColor)
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.brandBlack)
                    .lineLimit(2)
                    .kerning(-0.3)

                HStack(spacing: 5) {
                    Text(article.date)
                    Circle().frame(width: 2.5, height: 2.5).foregroundStyle(.brandGrayLight)
                    Text(article.readTime)
                }
                .font(.system(size: 12))
                .foregroundStyle(.brandGrayLight)
            }
            .padding(.horizontal, 13)
            .padding(.top, 11)
            .padding(.bottom, 14)
        }
        .frame(width: 196)
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.white.opacity(0.8), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}
