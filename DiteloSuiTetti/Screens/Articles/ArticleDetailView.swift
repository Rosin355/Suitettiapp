import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss

    private var plainBody: String {
        HTMLTextFormatter.plainText(from: article.body)
    }

    private var heroTitle: String {
        article.title
            .replacingOccurrences(of: "\\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Suppress excerpt when the body already opens with the same text (common CMS pattern)
    private var shouldShowExcerpt: Bool {
        guard !article.excerpt.isEmpty else { return false }
        let body = plainBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let excerpt = article.excerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty || !body.hasPrefix(excerpt)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                contentSection
            }
            // containerRelativeFrame ensures the VStack is exactly the scroll view's width,
            // preventing text overflow when maxWidth:.infinity resolves unconstrained inside ScrollView
            .containerRelativeFrame(.horizontal)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background(.brandCream)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 16)
        }
        .overlay(alignment: .top) {
            HStack(alignment: .top) {
                backButton
                Spacer()
                shareButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .safeAreaPadding(.top)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        DetailHeroView(
            imageURL: article.imageURL,
            fallbackColors: article.thumbnailColors,
            label: article.category,
            title: heroTitle,
            height: 430,
            maxTitleLines: 4
        )
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            metadataRow
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Rectangle()
                .fill(.brandSep)
                .frame(height: 1)
                .padding(.horizontal, 24)
                .padding(.top, 14)

            if shouldShowExcerpt {
                Text(article.excerpt)
                    .font(.system(size: 16).italic())
                    .foregroundStyle(.brandGray)
                    .lineSpacing(5)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
            }

            if !plainBody.isEmpty {
                Text(plainBody)
                    .font(.system(size: 17))
                    .foregroundStyle(.brandBlack)
                    .lineSpacing(8)
                    .padding(.horizontal, 24)
                    .padding(.top, shouldShowExcerpt ? 16 : 20)
                    .padding(.bottom, 100)
            } else if !article.excerpt.isEmpty {
                Text(article.excerpt)
                    .font(.system(size: 17))
                    .foregroundStyle(.brandBlack)
                    .lineSpacing(8)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 28))
                        .foregroundStyle(.brandGrayLight)
                    Text("Contenuto non disponibile.")
                        .font(.system(size: 15))
                        .foregroundStyle(.brandGrayLight)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadataRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11))
            Text(article.fullDate)
            Circle().frame(width: 3, height: 3)
            Image(systemName: "clock")
                .font(.system(size: 11))
            Text(article.readTime + " di lettura")
        }
        .font(.system(size: 13))
        .foregroundStyle(.brandGray)
    }

    // MARK: - Floating buttons

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.black.opacity(0.35))
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                )
        }
        .accessibilityLabel("Torna indietro")
    }

    @ViewBuilder
    private var shareButton: some View {
        if let shareURL = URL(string: AppEnvironment.websiteURL.absoluteString + "/articoli/" + article.slug) {
            ShareLink(item: shareURL) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.black.opacity(0.35))
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                    )
            }
            .accessibilityLabel("Condividi articolo")
        }
    }
}

#Preview("Short title") {
    NavigationStack {
        ArticleDetailView(article: Article(
            category: "Bene Comune",
            categoryColor: .brandRed,
            thumbnailColors: [.brandRed],
            title: "Sussidiarietà",
            date: "14 mag", fullDate: "14 mag 2026", readTime: "2 min"
        ))
    }
    .environment(ArticleStore(service: StubEditorialService()))
}

#Preview("Medium title") {
    NavigationStack {
        ArticleDetailView(article: Article.all[0])
    }
    .environment(ArticleStore(service: StubEditorialService()))
}

#Preview("Long title (real)") {
    NavigationStack {
        ArticleDetailView(article: Article(
            category: "Non autosufficienza",
            categoryColor: .brandRed,
            thumbnailColors: [.brandRed],
            title: "Non autosufficienza, Napolitano (Sui Tetti): con i 3 miliardi per i più fragili dal vice ministro Bellucci iniziativa strategica",
            date: "20 mag", fullDate: "20 mag 2026", readTime: "5 min"
        ))
    }
    .environment(ArticleStore(service: StubEditorialService()))
}
