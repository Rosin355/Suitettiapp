import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss

    private var plainBody: String {
        HTMLTextFormatter.plainText(from: article.body)
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
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background(.brandCream)
        .toolbar(.hidden, for: .navigationBar)
        // safeAreaInset adds clearance at the bottom so the floating tab bar never
        // covers the last line of body text
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 16)
        }
        // Buttons are pinned outside the scroll view — they never scroll away
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
        RemoteImageView(url: article.imageURL, fallbackColors: article.thumbnailColors)
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .clipped()
            .accessibilityHidden(true)
            .overlay(alignment: .bottom) {
                // Taller gradient so even a 4–5 line title stays readable over any image
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55), .black.opacity(0.88)],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: .bottom
                )
                .frame(height: 260)
            }
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 10) {
                    CategoryChip(
                        text: article.category,
                        color: .white,
                        background: .white.opacity(0.2)
                    )
                    Text(article.title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                        .kerning(-0.4)
                        .lineSpacing(2)
                        // Allow up to 5 lines; shrink slightly for very long Italian headlines
                        .lineLimit(5)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                // 24 pt side margins — keeps text away from screen edges
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
                    // 100 pt bottom — generous enough for the floating tab bar on all
                    // iPhone screen sizes, including iPhone Pro Max with home indicator
                    .padding(.bottom, 100)
            } else if !article.excerpt.isEmpty {
                // Body missing but excerpt exists — show excerpt as the content
                Text(article.excerpt)
                    .font(.system(size: 17))
                    .foregroundStyle(.brandBlack)
                    .lineSpacing(8)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
            } else {
                // Nothing to show
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
        }
        .glassEffect(.regular.interactive(), in: .circle)
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
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel("Condividi articolo")
        }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: Article.all[0])
    }
    .environment(ArticleStore(service: StubEditorialService()))
}
