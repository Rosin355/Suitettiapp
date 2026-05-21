import SwiftUI

struct HomeFeaturedArticlesSection: View {
    @Binding var selectedTab: AppTab
    @Environment(ArticleStore.self) private var store

    var body: some View {
        if !store.articles.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "In evidenza", action: "Tutti") {
                    selectedTab = .articoli
                }
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(store.articles.prefix(3)) { article in
                            Button {
                                selectedTab = .articoli
                            } label: {
                                FeaturedArticleCard(article: article)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DT.padding)
                    .padding(.bottom, 6)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
