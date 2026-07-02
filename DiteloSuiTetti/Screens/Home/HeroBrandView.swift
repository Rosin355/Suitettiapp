import SwiftUI

/// The editorial typography lockup at the centre of the home hero.
/// "Ditelo" (bold sans) + "sui Tetti." (Georgia italic) + tagline.
/// Accepts responsive font sizes from HomeHeroSection so the lockup
/// scales gracefully on compact-height devices (SE, mini, non-Max).
struct HeroBrandView: View {
    var titleSize: CGFloat = 72
    var subtitleSize: CGFloat = 66
    var taglineBottomPadding: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tagline
                .padding(.bottom, taglineBottomPadding)

            Text("Ditelo")
                .font(.system(size: titleSize, weight: .black))
                .foregroundStyle(.white)
                .kerning(-3.5 * titleSize / 72)

            Text("sui Tetti.")
                .font(.georgiaItalic(subtitleSize))
                .foregroundStyle(.brandYellowLight)
                .kerning(-2.5 * subtitleSize / 66)
        }
        // Read the lockup as one header instead of three fragments ("Ditelo",
        // "sui Tetti.", "PER IL BENE COMUNE") in VoiceOver.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ditelo sui Tetti — per il bene comune")
        .accessibilityAddTraits(.isHeader)
    }

    private var tagline: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(.white.opacity(0.36))
                .frame(width: 18, height: 1)
            Text("PER IL BENE COMUNE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.68))
                .kerning(2.0)
        }
    }
}

#Preview {
    ZStack(alignment: .topLeading) {
        Color(red: 0.91, green: 0.10, blue: 0.17).ignoresSafeArea()
        HeroBrandView()
            .padding(24)
    }
}
