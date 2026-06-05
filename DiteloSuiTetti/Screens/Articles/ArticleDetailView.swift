import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    /// When `true`, the view is embedded in an iPad split panel (not pushed via NavigationLink).
    /// Suppresses the floating back button and removes the top-edge safe area override.
    var isEmbedded: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var plainBody: String {
        HTMLTextFormatter.plainText(from: article.body)
    }

    private var heroTitle: String {
        TextNormalizer.singleLineClean(article.title)
    }

    private var shouldShowExcerpt: Bool {
        guard !article.excerpt.isEmpty else { return false }
        let body = plainBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let excerpt = article.excerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty || !body.hasPrefix(excerpt)
    }

    /// Hero image height — reduced when embedded in iPad panel.
    private var heroHeight: CGFloat {
        isEmbedded ? 240 : 340
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                // Constrain title + body to a readable max-width so text does not span
                // the full detail panel on iPad (which can be 700–900pt wide).
                VStack(spacing: 0) {
                    titleCardSection
                    contentSection
                }
                .frame(maxWidth: DT.readableMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .containerRelativeFrame(.horizontal)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: isEmbedded ? [] : [.top])
        .background(.brandCream)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 16)
        }
        .overlay(alignment: .top) {
            HStack(alignment: .top) {
                if !isEmbedded {
                    backButton
                }
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
        DetailHeroImage(
            imageURL: article.imageURL,
            fallbackColors: article.thumbnailColors,
            height: heroHeight
        )
    }

    // MARK: - Title card

    private var titleCardSection: some View {
        DetailTitleCard(
            label: article.category,
            labelColor: article.categoryColor,
            title: heroTitle
        ) {
            metadataRow
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if shouldShowExcerpt {
                Text(article.excerpt)
                    .font(.system(size: 16).italic())
                    .foregroundStyle(.brandGray)
                    .lineSpacing(5)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
            }

            if !plainBody.isEmpty {
                Text(plainBody)
                    .font(.system(size: 17))
                    .foregroundStyle(.brandBlack)
                    .lineSpacing(8)
                    .padding(.horizontal, 24)
                    .padding(.top, shouldShowExcerpt ? 16 : 24)
                    .padding(.bottom, 24)
            } else if !article.excerpt.isEmpty {
                Text(article.excerpt)
                    .font(.system(size: 17))
                    .foregroundStyle(.brandBlack)
                    .lineSpacing(8)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
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
                .padding(.bottom, 24)
            }

            relatedDocumentsSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            NSLog("[ArticleDetailView] opened slug '%@' relatedDocs: %d",
                  article.slug, article.relatedDocuments.count)
        }
    }

    @ViewBuilder
    private var relatedDocumentsSection: some View {
        if !article.relatedDocuments.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(.brandSep)
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                Text("Documenti allegati")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.brandGray)
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                VStack(spacing: 8) {
                    ForEach(article.relatedDocuments) { doc in
                        LinkedDocumentCard(document: doc)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        } else {
            Color.clear.frame(height: 100).allowsHitTesting(false)
        }
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
                .frame(width: 44, height: 44)
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
                    .frame(width: 44, height: 44)
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

#Preview("iPad embedded") {
    ArticleDetailView(article: Article.all[0], isEmbedded: true)
        .environment(ArticleStore(service: StubEditorialService()))
}
