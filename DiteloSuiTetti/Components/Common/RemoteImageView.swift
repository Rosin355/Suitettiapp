import SwiftUI

/// Loads a remote image (via the persistent `ImageCache`) and falls back to the
/// official Ditelo sui Tetti brand logo when there is no URL or the download fails.
///
/// Editorial content never shows a random gradient: a missing or broken image is
/// always replaced by the brand mark on a cream background, which reads as an
/// intentional placeholder at any aspect ratio.
struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    /// Optional title, used only for diagnostic logging.
    var logTitle: String? = nil
    /// Legacy gradient colors. Retained for source compatibility with existing call
    /// sites; no longer used for rendering — the brand logo is the editorial fallback.
    var fallbackColors: [Color] = [.brandRed, Color(red: 192/255, green: 20/255, blue: 30/255)]

    /// Asset name of the reusable brand fallback (see Assets.xcassets/dst_fallback_logo).
    static let fallbackAssetName = "dst_fallback_logo"

    @State private var uiImage: UIImage?
    @State private var phase: LoadPhase = .idle

    private enum LoadPhase { case idle, loading, loaded, failed }

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if phase == .loading {
                loadingPlaceholder
            } else {
                brandFallback
            }
        }
        .task(id: url) { await load() }
    }

    // MARK: - Loading

    private func load() async {
        guard let url else {
            uiImage = nil
            phase = .failed
            NSLog("[RemoteImageView] using fallback image — url nil (title: %@)", logTitle ?? "—")
            return
        }
        uiImage = nil
        phase = .loading
        if let image = await ImageCache.shared.image(for: url) {
            uiImage = image
            phase = .loaded
        } else {
            phase = .failed
            NSLog("[ImageCache] failed — fallback shown (title: %@, url: %@)",
                  logTitle ?? "—", url.absoluteString)
        }
    }

    // MARK: - Fallback / placeholder

    /// Official brand logo on a cream backing. `scaledToFit` guarantees the full mark
    /// is always visible (never cropped) whether the frame is square (list thumbnail)
    /// or wide (featured card / detail hero); the cream backing matches the logo's own
    /// background so there is no visible seam.
    private var brandFallback: some View {
        ZStack {
            Color.brandCream
            Image(Self.fallbackAssetName)
                .resizable()
                .scaledToFit()
        }
        .accessibilityHidden(true)
    }

    private var loadingPlaceholder: some View {
        Color.brandCream
            .overlay { ProgressView().tint(.brandRed.opacity(0.5)) }
    }
}

#Preview("States") {
    VStack(spacing: 16) {
        RemoteImageView(url: nil, logTitle: "No image article")
            .frame(width: 120, height: 120)
            .clipShape(.rect(cornerRadius: 16))
        RemoteImageView(url: nil)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipShape(.rect(cornerRadius: 16))
    }
    .padding()
    .background(Color.brandCream)
}
