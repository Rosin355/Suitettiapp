import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss

    private var plainBody: String {
        HTMLTextFormatter.plainText(from: article.body)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                contentSection
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background(.brandCream)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            RemoteImageView(url: article.imageURL, fallbackColors: article.thumbnailColors)
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .clipped()
                .accessibilityHidden(true)

            // Dark gradient — ensures title is always legible
            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: UnitPoint(x: 0.5, y: 0.3),
                endPoint: .bottom
            )

            // Category + title pinned to the bottom of the hero
            VStack(alignment: .leading, spacing: 10) {
                CategoryChip(text: article.category, color: .white, background: .white.opacity(0.18))
                Text(article.title)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-0.5)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 400)
        // Floating back + share buttons sit at the very top, inside safe area
        .overlay(alignment: .top) {
            HStack {
                backButton
                Spacer()
                shareButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .safeAreaPadding(.top)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            metadataRow
                .padding(.top, 20)
                .padding(.horizontal, 20)

            Rectangle()
                .fill(.brandSep)
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            if !article.excerpt.isEmpty {
                Text(article.excerpt)
                    .font(.system(size: 16).italic())
                    .foregroundStyle(.brandGray)
                    .lineSpacing(5)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }

            if !plainBody.isEmpty {
                Text(plainBody)
                    .font(.system(size: 17))
                    .foregroundStyle(.brandBlack)
                    .lineSpacing(7)
                    .padding(.horizontal, 20)
                    .padding(.top, article.excerpt.isEmpty ? 20 : 16)
                    .padding(.bottom, 48)
            } else {
                Color.clear.frame(height: 48)
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11))
            Text(article.fullDate)
            Circle()
                .frame(width: 3, height: 3)
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
