import SwiftUI

/// Loads a remote image with a branded gradient fallback.
/// Use `fallbackColors` to match the article's palette when no image is available.
struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var fallbackColors: [Color] = [.brandRed, Color(red: 192/255, green: 20/255, blue: 30/255)]

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderGradient
                        .overlay {
                            ProgressView()
                                .tint(.white.opacity(0.7))
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholderGradient
                @unknown default:
                    placeholderGradient
                }
            }
        } else {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: fallbackColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
