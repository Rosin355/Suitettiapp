import SwiftUI

/// Self-contained modal that shows a web page in its own `NavigationStack` with a
/// Close button. Reusable for any "open on the website" flow; presented via `.sheet`.
struct WebSheet: View {
    let title: String
    let url: URL

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WebPageView(title: title, url: url)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Chiudi") { dismiss() }
                            .accessibilityLabel("Chiudi")
                    }
                }
        }
    }
}

#Preview {
    WebSheet(title: "3° Festival", url: AppEnvironment.festivalURL)
}
