import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @State private var scrolledPastHero = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
                    // TODO: Future promotional banner slot — disabled for v1.0 because the
                    // event is already surfaced in Prossimi eventi. Re-enable HomeReferendumCTA
                    // (below) and wire its tap action when a real destination exists.
                    // HomeReferendumCTA()
                    //     .padding(.bottom, 8)
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

private struct HomeReferendumCTA: View {
    var body: some View {
        GCard {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    CategoryChip(
                        text: "FESTIVAL",
                        color: .brandYellow,
                        background: .brandYellow.opacity(0.18)
                    )
                    Text("Scopri l'evento del 16 giugno")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(-0.4)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.brandRed)
                    .clipShape(.rect(cornerRadius: 12))
                    .shadow(color: .brandRed.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [.brandBlack, Color(red: 37/255, green: 37/255, blue: 37/255)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
        }
        .padding(.horizontal, DT.padding)
    }
}

#Preview {
    NavigationStack {
        HomeView(selectedTab: .constant(.home))
    }
    .environment(ArticleStore(service: StubEditorialService()))
    .environment(EventStore(service: StubEventService()))
}
