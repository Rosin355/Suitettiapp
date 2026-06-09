import SwiftUI

struct HomeFeaturedArticlesSection: View {
    @Binding var selectedTab: AppTab
    @Environment(ArticleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Namespace private var zoomNamespace

    var body: some View {
        if !store.articles.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "In evidenza", action: "Vedi tutti") {
                    selectedTab = .articoli
                }

                let featured = Array(store.articles.prefix(6))

                if horizontalSizeClass == .regular {
                    // iPad: two-column grid
                    iPadGrid(featured)
                        .padding(.horizontal, DT.padding)
                        .padding(.bottom, 12)
                } else {
                    // iPhone: vertical card list
                    iPhoneList(featured)
                        .padding(.horizontal, DT.padding)
                        .padding(.bottom, 12)
                }
            }
            .appearAnimation(delay: 0.1)
        }
    }

    // MARK: - iPad two-column grid

    private func iPadGrid(_ articles: [Article]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(articles) { article in
                NavigationLink {
                    ArticleDetailView(article: article)
                        .navigationTransition(.zoom(sourceID: article.id, in: zoomNamespace))
                } label: {
                    iPadArticleCard(article)
                        .matchedTransitionSource(id: article.id, in: zoomNamespace)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    @ViewBuilder private func iPadArticleCard(_ article: Article) -> some View {
        HStack(spacing: 12) {
            RemoteImageView(url: article.imageURL, logTitle: article.title, fallbackColors: article.thumbnailColors)
                .frame(width: 72, height: 72)
                .clipShape(.rect(cornerRadius: 14))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                CategoryChip(
                    text: article.category,
                    color: article.categoryColor,
                    background: article.categoryColor.opacity(0.13)
                )
                Text(article.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.brandBlack)
                    .lineLimit(2)
                    .kerning(-0.25)
                HStack(spacing: 5) {
                    Text(article.fullDate)
                    Circle().frame(width: 2.5, height: 2.5).foregroundStyle(.brandGrayLight)
                    Text(article.readTime)
                }
                .font(.system(size: 12))
                .foregroundStyle(.brandGrayLight)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
    }

    // MARK: - iPhone vertical list

    private func iPhoneList(_ articles: [Article]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                NavigationLink {
                    ArticleDetailView(article: article)
                        .navigationTransition(.zoom(sourceID: article.id, in: zoomNamespace))
                } label: {
                    ArticleListRow(article: article, isLast: index == articles.count - 1)
                        .matchedTransitionSource(id: article.id, in: zoomNamespace)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
    }
}
