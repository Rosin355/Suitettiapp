import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                NavigationStack {
                    HomeView(selectedTab: $selectedTab)
                }
            }
            Tab("Articoli", systemImage: "doc.text.fill", value: AppTab.articoli) {
                NavigationStack {
                    ArticoliView()
                        .navigationTitle("Articoli")
                }
            }
            Tab("Sostieni", systemImage: "heart.fill", value: AppTab.sostieni) {
                NavigationStack {
                    SosteniView()
                        .navigationTitle("Sostieni")
                }
            }
        }
        .tint(.brandRed)
    }
}

#Preview {
    ContentView()
        .environment(ArticleStore(service: StubEditorialService()))
}
