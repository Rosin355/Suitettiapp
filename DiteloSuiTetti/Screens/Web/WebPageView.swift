import SwiftUI

/// Presents a remote page in an in-app web view with explicit loading and error
/// states (Definition of Done: loading + error + graceful fallback). Used inside a
/// `NavigationStack` — e.g. wrapped by `WebSheet` for the Home festival spotlight.
struct WebPageView: View {
    let title: String
    let url: URL

    @Environment(\.openURL) private var openURL
    @State private var isLoading = true
    @State private var loadError: Error?
    /// Bumping this recreates the underlying web view, forcing a fresh load on retry.
    @State private var reloadToken = 0

    var body: some View {
        ZStack {
            InAppWebView(url: url, isLoading: $isLoading, loadError: $loadError)
                .id(reloadToken)
                .ignoresSafeArea(edges: .bottom)
                .opacity(loadError == nil ? 1 : 0)
                .accessibilityLabel(Text("Contenuto web: \(title)"))

            if loadError == nil, isLoading {
                ProgressView("Caricamento…")
                    .controlSize(.large)
                    .tint(.brandRed)
                    .accessibilityLabel("Caricamento della pagina in corso")
            }

            if loadError != nil {
                EmptyStateView(
                    icon: "wifi.slash",
                    title: "Impossibile caricare la pagina",
                    subtitle: "Controlla la connessione e riprova, oppure apri la pagina nel browser.",
                    iconTint: .brandGray,
                    primaryLabel: "Riprova",
                    primaryAction: reload,
                    secondaryLabel: "Apri nel browser",
                    secondaryAction: { openURL(url) }
                )
                .background(.brandCream)
                .transition(.opacity)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    private func reload() {
        loadError = nil
        isLoading = true
        reloadToken += 1
    }
}

#Preview {
    NavigationStack {
        WebPageView(title: "Festival", url: URL(string: "https://www.suitetti.org")!)
    }
}
