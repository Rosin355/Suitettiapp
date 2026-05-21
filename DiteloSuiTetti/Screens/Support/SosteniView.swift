import SwiftUI

struct SosteniView: View {
    private let ways: [(icon: String, title: String, detail: String)] = [
        (icon: "🤝", title: "Diventa associazione aderente",
         detail: "La tua associazione può entrare nella rete e contribuire alla voce comune."),
        (icon: "📣", title: "Condividi sui social",
         detail: "Amplifica il messaggio: condividi i nostri contenuti e usa #DitelosuiTetti."),
        (icon: "📰", title: "Scrivi e pubblica",
         detail: "Contribuisci con articoli e riflessioni sul bene comune, la famiglia e l'educazione."),
        (icon: "📅", title: "Organizza un evento",
         detail: "Organizza un presidio, un incontro o un'assemblea nella tua città."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SupportHeroSection()
                SupportActionsSection(ways: ways)
            }
        }
        .scrollIndicators(.hidden)
        .background(.brandCream)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SosteniView()
            .navigationTitle("Sostieni")
    }
}
