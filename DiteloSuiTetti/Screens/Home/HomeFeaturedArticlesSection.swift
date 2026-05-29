import SwiftUI

struct HomeFeaturedArticlesSection: View {
    @Binding var selectedTab: AppTab
    @Environment(ArticleStore.self) private var store

    var body: some View {
        if !store.articles.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "In evidenza", action: "Vedi tutti") {
                    selectedTab = .articoli
                }

                let featured = Array(store.articles.prefix(5))
                VStack(spacing: 0) {
                    ForEach(Array(featured.enumerated()), id: \.element.id) { index, article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleListRow(article: article, isLast: index == featured.count - 1)
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
                .padding(.horizontal, DT.padding)
                .padding(.bottom, 12)
            }
            .appearAnimation(delay: 0.1)
        }
    }
}
