import SwiftUI

struct ArticlesListSection: View {
    let filtered: [Article]
    let showFeatured: Bool

    var body: some View {
        VStack(spacing: 0) {
            if showFeatured {
                ArticlesFeaturedCard()
                    .padding(.horizontal, DT.padding)
                    .padding(.bottom, 18)
            }

            articleList
                .padding(.horizontal, DT.padding)
                .padding(.bottom, 8)
        }
    }

    private var articleList: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.white.opacity(0.8))
                .frame(height: 1)

            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, article in
                NavigationLink(destination: ArticleDetailView(article: article)) {
                    ArticleListRow(
                        article: article,
                        isLast: index == filtered.count - 1
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 0.5)
    }
}

private struct ArticlesFeaturedCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.brandRed, Color(red: 192/255, green: 20/255, blue: 30/255),
                         Color(red: 139/255, green: 14/255, blue: 21/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 230)

            Circle().fill(.white.opacity(0.08))
                .frame(width: 180, height: 180)
                .offset(x: 260, y: -110)

            Circle().fill(.black.opacity(0.06))
                .frame(width: 120, height: 120)
                .offset(x: -10, y: -80)

            CategoryChip(text: "In evidenza", color: .white, background: .white.opacity(0.18))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(18)

            VStack(alignment: .leading, spacing: 6) {
                Text("Ditelo sui Tetti: un anno di voce civica in Italia")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-0.4)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text("16 mag 2026")
                    Circle()
                        .frame(width: 2.5, height: 2.5)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("5 min di lettura")
                }
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .overlay(alignment: .top) {
                Rectangle().fill(.white.opacity(0.18)).frame(height: 0.5)
            }
        }
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .shadow(color: .brandRed.opacity(0.22), radius: 14, x: 0, y: 6)
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}
