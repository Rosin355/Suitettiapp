import SwiftUI

struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var fallbackColors: [Color] = [.brandRed, Color(red: 192/255, green: 20/255, blue: 30/255)]

    @State private var uiImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholderGradient
                    .overlay {
                        if isLoading {
                            ProgressView().tint(.white.opacity(0.7))
                        }
                    }
            }
        }
        .task(id: url) {
            guard let url else {
                uiImage = nil
                isLoading = false
                return
            }
            uiImage = nil
            isLoading = true
            let result = await ImageCache.shared.image(for: url)
            isLoading = false
            uiImage = result
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(colors: fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
