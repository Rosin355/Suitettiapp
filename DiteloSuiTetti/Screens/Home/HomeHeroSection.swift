import SwiftUI

struct HomeHeroSection: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            heroContent
            HeroStatsView()
        }
        .background(Color(red: 0.91, green: 0.10, blue: 0.17))
        .clipped()
    }

    private var heroContent: some View {
        ZStack(alignment: .topLeading) {
            HeroBackgroundView()

            // Bottom vignette — deepens separation from the stats strip
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.20)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 72)
            }
            .allowsHitTesting(false)

            HeroBrandView()
                .padding(.horizontal, 24)
                .safeAreaPadding(.top)
                .padding(.top, DT.topBarContentOffset)
                .padding(.bottom, 36)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55).delay(0.12)) {
                appeared = true
            }
        }
    }
}

#Preview {
    HomeHeroSection()
}
