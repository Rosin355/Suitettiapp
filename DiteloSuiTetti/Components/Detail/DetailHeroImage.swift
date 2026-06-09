import SwiftUI

struct DetailHeroImage: View {
    let imageURL: URL?
    let fallbackColors: [Color]
    var height: CGFloat = 340
    var accessibilityLabel: String? = nil
    var logTitle: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            RemoteImageView(url: imageURL, logTitle: logTitle ?? accessibilityLabel, fallbackColors: fallbackColors)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                colors: [.clear, .black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: height * 0.40)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .accessibilityHidden(accessibilityLabel == nil)
        .accessibilityLabel(accessibilityLabel ?? "")
    }
}

#Preview("Article hero") {
    DetailHeroImage(
        imageURL: nil,
        fallbackColors: [.brandRed, Color(red: 192/255, green: 20/255, blue: 30/255)],
        height: 340
    )
}

#Preview("Event hero") {
    DetailHeroImage(
        imageURL: nil,
        fallbackColors: [Color(red: 91/255, green: 82/255, blue: 208/255),
                         Color(red: 55/255, green: 48/255, blue: 155/255)],
        height: 340
    )
}
