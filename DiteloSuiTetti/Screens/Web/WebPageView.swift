import SwiftUI

struct WebPageView: View {
    let title: String
    let url: URL
    @State private var isLoading = true

    var body: some View {
        ZStack {
            InAppWebView(url: url)
                .ignoresSafeArea(edges: .bottom)

            if isLoading {
                ProgressView()
                    .task {
                        // Brief delay so the web view has time to start rendering
                        try? await Task.sleep(for: .milliseconds(600))
                        isLoading = false
                    }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}
