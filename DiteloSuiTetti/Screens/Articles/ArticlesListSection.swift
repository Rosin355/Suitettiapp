import SwiftUI

struct ArticlesListSection: View {
    let filtered: [Article]
    let showFeatured: Bool
    /// When set (iPad split panel), tapping a row calls this closure instead of pushing a NavigationLink.
    var onSelect: ((Article) -> Void)? = nil
    /// Highlights the currently selected article in the left panel list.
    var selectedArticle: Article? = nil

    @Namespace private var zoomNamespace

    // When showing the featured card, the first article is the hero;
    // the list below shows the rest to avoid duplication.
    private var featuredArticle: Article? {
        showFeatured ? filtered.first : nil
    }

    private var listArticles: [Article] {
        showFeatured ? Array(filtered.dropFirst()) : filtered
    }

    var body: some View {
        VStack(spacing: 0) {
            // Featured hero card — only when "Tutto" and articles exist
            if let featured = featuredArticle {
                featuredCardLink(for: featured)
                    .buttonStyle(.plain)
                    .padding(.horizontal, DT.padding)
                    .padding(.bottom, 18)
            }

            // Article list
            if listArticles.isEmpty {
                if !showFeatured {
                    emptyFilteredState
                        .padding(.horizontal, DT.padding)
                }
                // When showFeatured but only one article exists: just the hero.
            } else {
                articleList
                    .padding(.horizontal, DT.padding)
                    .padding(.bottom, 16)
            }

            // Clearance for floating tab bar — must not intercept taps above it
            Color.clear.frame(height: 130).allowsHitTesting(false)
        }
    }

    // MARK: - Featured card

    @ViewBuilder
    private func featuredCardLink(for article: Article) -> some View {
        if let onSelect {
            Button { onSelect(article) } label: {
                ArticlesFeaturedCard(
                    article: article,
                    isSelected: selectedArticle?.id == article.id
                )
            }
        } else {
            NavigationLink {
                ArticleDetailView(article: article)
                    .navigationTransition(.zoom(sourceID: article.id, in: zoomNamespace))
            } label: {
                ArticlesFeaturedCard(article: article, isSelected: false)
                    .matchedTransitionSource(id: article.id, in: zoomNamespace)
            }
        }
    }

    // MARK: - List

    private var articleList: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.white.opacity(0.8))
                .frame(height: 1)

            ForEach(Array(listArticles.enumerated()), id: \.element.id) { index, article in
                articleRow(article, isLast: index == listArticles.count - 1)
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

    @ViewBuilder
    private func articleRow(_ article: Article, isLast: Bool) -> some View {
        if let onSelect {
            Button {
                onSelect(article)
            } label: {
                ArticleListRow(article: article, isLast: isLast)
                    .background(
                        selectedArticle?.id == article.id
                        ? Color.brandRed.opacity(0.05)
                        : Color.clear
                    )
            }
            .buttonStyle(PressableCardStyle())
        } else {
            NavigationLink {
                ArticleDetailView(article: article)
                    .navigationTransition(.zoom(sourceID: article.id, in: zoomNamespace))
            } label: {
                ArticleListRow(article: article, isLast: isLast)
                    .matchedTransitionSource(id: article.id, in: zoomNamespace)
            }
            .buttonStyle(PressableCardStyle())
        }
    }

    // MARK: - Empty state (specific category with no articles)

    private var emptyFilteredState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.brandGrayLight)
            Text("Nessun articolo in questa categoria.")
                .font(.system(size: 15))
                .foregroundStyle(.brandGrayLight)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Featured hero card

private struct ArticlesFeaturedCard: View {
    let article: Article
    var isSelected: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Article image — falls back to branded gradient if nil or load fails
            RemoteImageView(url: article.imageURL, logTitle: article.title, fallbackColors: article.thumbnailColors)
                .frame(height: 230)
                .frame(maxWidth: .infinity)
                .clipped()

            // Bottom vignette for text legibility
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.18),
                    .black.opacity(0.65),
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            // Category chip
            CategoryChip(
                text: article.category,
                color: .white,
                background: .black.opacity(0.38)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)

            // Title + metadata
            VStack(alignment: .leading, spacing: 5) {
                Text(article.title)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-0.4)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)

                HStack(spacing: 6) {
                    Text(article.fullDate)
                    Circle()
                        .fill(.white.opacity(0.45))
                        .frame(width: 2.5, height: 2.5)
                    Text(article.readTime + " di lettura")
                }
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .frame(height: 230)
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.brandRed, lineWidth: 2)
            }
        }
        .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 6)
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
    }
}
