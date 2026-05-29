import SwiftUI

/// The editorial typography lockup at the centre of the home hero.
/// "Ditelo" (bold sans) + "sui Tetti." (Georgia italic) + tagline.
struct HeroBrandView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tagline
                .padding(.bottom, 20)

            Text("Ditelo")
                .font(.system(size: 72, weight: .black))
                .foregroundStyle(.white)
                .kerning(-3.5)

            Text("sui Tetti.")
                .font(.georgiaItalic(66))
                .foregroundStyle(.brandYellowLight)
                .kerning(-2.5)
        }
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
