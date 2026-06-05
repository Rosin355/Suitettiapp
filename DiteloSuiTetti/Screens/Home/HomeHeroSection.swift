import SwiftUI
import UIKit

// MARK: - Responsive sizing

private struct HeroSizeConfig {
    let titleSize: CGFloat
    let subtitleSize: CGFloat
    let taglineBottomPadding: CGFloat
    let contentBottomPadding: CGFloat
    /// Max width for the brand lockup — constrains the text block on wide iPad canvases
    /// while the full-bleed background still fills the screen.
    let brandMaxWidth: CGFloat

    /// Derives the right config from the device's physical screen height.
    /// Uses UIWindowScene (non-deprecated) with a sensible fallback.
    static func responsive() -> HeroSizeConfig {
        let h: CGFloat = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen.bounds.height ?? 852

        switch h {
        case ..<700:        // iPhone SE (667 pt)
            return HeroSizeConfig(titleSize: 54, subtitleSize: 48,
                                  taglineBottomPadding: 10, contentBottomPadding: 18,
                                  brandMaxWidth: .infinity)
        case 700..<820:     // iPhone mini (812 pt)
            return HeroSizeConfig(titleSize: 62, subtitleSize: 56,
                                  taglineBottomPadding: 14, contentBottomPadding: 24,
                                  brandMaxWidth: .infinity)
        case 820..<880:     // iPhone 15 / 16 non-Max (852 pt)
            return HeroSizeConfig(titleSize: 66, subtitleSize: 60,
                                  taglineBottomPadding: 16, contentBottomPadding: 28,
                                  brandMaxWidth: .infinity)
        case 880..<1000:    // iPhone Max / Plus (932 pt)
            return HeroSizeConfig(titleSize: 72, subtitleSize: 66,
                                  taglineBottomPadding: 20, contentBottomPadding: 36,
                                  brandMaxWidth: .infinity)
        default:            // iPad (screen height ≥ 1000 pt, e.g. iPad mini 1133 pt)
            return HeroSizeConfig(titleSize: 88, subtitleSize: 78,
                                  taglineBottomPadding: 26, contentBottomPadding: 60,
                                  brandMaxWidth: 580)
        }
    }
}

// MARK: - View

struct HomeHeroSection: View {
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sizeConfig: HeroSizeConfig { HeroSizeConfig.responsive() }

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

            HeroBrandView(
                titleSize: sizeConfig.titleSize,
                subtitleSize: sizeConfig.subtitleSize,
                taglineBottomPadding: sizeConfig.taglineBottomPadding
            )
            .frame(maxWidth: sizeConfig.brandMaxWidth, alignment: .leading)
            .padding(.horizontal, 24)
            .safeAreaPadding(.top)
            .padding(.top, DT.topBarContentOffset)
            .padding(.bottom, sizeConfig.contentBottomPadding)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.55).delay(0.12)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    HomeHeroSection()
}
