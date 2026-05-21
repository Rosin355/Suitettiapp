import SwiftUI

struct HomeHeroSection: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(0.07))
                    .frame(width: 240, height: 240)
                    .offset(x: 160, y: -70)
                Circle()
                    .fill(.black.opacity(0.05))
                    .frame(width: 160, height: 160)
                    .offset(x: -40, y: 60)

                VStack(alignment: .leading, spacing: 0) {
                    Text("PER IL BENE COMUNE")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .kerning(1.8)
                        .padding(.bottom, 14)

                    Text("Ditelo")
                        .font(.system(size: 66, weight: .black))
                        .foregroundStyle(.white)
                        .kerning(-3)

                    Text("sui Tetti.")
                        .font(Font.custom("Georgia", size: 63).italic())
                        .foregroundStyle(.brandYellowLight)
                        .kerning(-2)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 22)
                .safeAreaPadding(.top)
                .padding(.top, DT.topBarContentOffset)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HomeStatsStrip()
        }
        .background(.brandRed)
        .clipped()
    }
}
