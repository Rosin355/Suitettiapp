import SwiftUI

struct DetailHeroView: View {
    let imageURL: URL?
    let fallbackColors: [Color]
    let label: String?
    let title: String
    var height: CGFloat = 420
    var maxTitleLines: Int = 4

    private var titleFont: Font {
        title.count > 95
            ? .system(size: 22, weight: .bold, design: .rounded)
            : .system(size: 26, weight: .bold, design: .rounded)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RemoteImageView(url: imageURL, fallbackColors: fallbackColors)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)

            LinearGradient(
                colors: [.clear, .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: height * 0.62)

            VStack(alignment: .leading, spacing: 10) {
                if let label, !label.isEmpty {
                    CategoryChip(text: label, color: .white, background: .white.opacity(0.2))
                }
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(maxTitleLines)
                    .minimumScaleFactor(0.86)
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 38)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }
}

#Preview("Short title") {
    DetailHeroView(
        imageURL: nil,
        fallbackColors: [.brandRed],
        label: "Bene Comune",
        title: "Sussidiarietà"
    )
}

#Preview("Medium title") {
    DetailHeroView(
        imageURL: nil,
        fallbackColors: [Color(red: 0.3, green: 0.2, blue: 0.6)],
        label: "Referendum",
        title: "Referendum sulla riforma della giustizia: le ragioni del sì"
    )
}

#Preview("Long title (real)") {
    DetailHeroView(
        imageURL: nil,
        fallbackColors: [Color(red: 0.2, green: 0.4, blue: 0.7)],
        label: "Non autosufficienza",
        title: "Non autosufficienza, Napolitano (Sui Tetti): con i 3 miliardi per i più fragili dal vice ministro Bellucci iniziativa strategica"
    )
}

#Preview("Event style") {
    DetailHeroView(
        imageURL: nil,
        fallbackColors: [Color(red: 91/255, green: 82/255, blue: 208/255)],
        label: "Convegno",
        title: "Non autosufficienza, Napolitano (Sui Tetti): con i 3 miliardi per i più fragili dal vice ministro Bellucci iniziativa strategica",
        height: 410,
        maxTitleLines: 3
    )
}
