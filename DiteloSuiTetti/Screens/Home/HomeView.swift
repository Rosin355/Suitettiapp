import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @State private var scrolledPastHero = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero + ticker span the full width on all devices
                HomeHeroSection()
                HeroTickerView()
                    .frame(maxWidth: .infinity)

                // Editorial content is constrained to a readable width on iPad
                VStack(spacing: 0) {
                    HomeFeaturedArticlesSection(selectedTab: $selectedTab)
                    HomeEventsSection()
                    HomeQuoteSection()
                    // Time-bound spotlight — opens the Festival page (rich web content:
                    // videos + extra material, not in the sync payload) in the external
                    // browser via SwiftUI openURL. Copy + destination URL are the only
                    // festival-specific values; swap them (and AppEnvironment.festivalURL)
                    // for a future promo.
                    HomePromoCard(
                        eyebrow: "SPECIALE",
                        title: "3° Festival — rivivi video e materiali",
                        accessibilityHintText: "Apre la pagina del Festival sul sito web"
                    ) {
                        openURL(AppEnvironment.festivalURL)
                    }
                    .padding(.horizontal, DT.padding)
                    .padding(.bottom, 8)
                    // Ensures last card scrolls fully above the floating glass tab bar
                    Color.clear.frame(height: 130)
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? DT.readableMaxWidth : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 0)
        .ignoresSafeArea()
        .background(.brandCream)
        .toolbar(.hidden, for: .navigationBar)
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { _, offset in
            let shouldShow = offset > 220
            if shouldShow != scrolledPastHero {
                scrolledPastHero = shouldShow
            }
        }
        .overlay(alignment: .top) {
            HomeTopBar(selectedTab: $selectedTab, scrolledPastHero: scrolledPastHero)
        }
    }
}

private struct HomeQuoteSection: View {
    var body: some View {
        GCard(tint: .brandYellow) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\u{201C}")
                    .font(.system(size: 48))
                    .foregroundStyle(.black.opacity(0.15))
                    .padding(.bottom, -8)

                Text("Una rete di cittadini che vuole fare sentire la propria voce per il bene comune.")
                    .font(Font.custom("Georgia", size: 17).italic())
                    .foregroundStyle(.brandBlack)
                    .lineSpacing(4)

                Text("Sui tetti · 2026")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.brandGray)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .padding(.horizontal, DT.padding)
        .padding(.bottom, 12)
    }
}

#Preview {
    NavigationStack {
        HomeView(selectedTab: .constant(.home))
    }
    .environment(ArticleStore(service: StubEditorialService()))
    .environment(EventStore(service: StubEventService()))
}
