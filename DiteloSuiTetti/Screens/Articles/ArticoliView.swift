import SwiftUI

struct ArticoliView: View {
    @Environment(ArticleStore.self) private var store
    @State private var selectedCategory = "Tutto"

    private var filtered: [Article] {
        selectedCategory == "Tutto"
            ? store.articles
            : store.articles.filter { $0.category == selectedCategory }
    }

    var body: some View {
        Group {
            if store.isLoading && store.articles.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.brandCream)
            } else if let errorMessage = store.errorMessage, store.articles.isEmpty {
                ContentUnavailableView {
                    Label("Errore di caricamento", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Riprova") {
                        Task { await store.load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .background(.brandCream)
            } else if store.articles.isEmpty {
                ContentUnavailableView("Nessun articolo", systemImage: "doc.text")
                    .background(.brandCream)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if let msg = store.offlineMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "wifi.slash").font(.system(size: 12))
                                Text(msg).font(.system(size: 13))
                            }
                            .foregroundStyle(.brandGray)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        }

                        ArticlesFilterBar(selectedCategory: $selectedCategory,
                                         categories: store.categories)
                            .padding(.top, 4)
                            .padding(.bottom, 16)

                        ArticlesListSection(
                            filtered: filtered,
                            showFeatured: selectedCategory == "Tutto"
                        )
                    }
                }
                .scrollIndicators(.hidden)
                .background(.brandCream)
                .refreshable { await store.refresh() }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .task { await store.load() }
        .onChange(of: store.categories) { _, newCategories in
            if !newCategories.contains(selectedCategory) {
                selectedCategory = "Tutto"
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArticoliView()
            .navigationTitle("Articoli")
            .environment(ArticleStore(service: StubEditorialService()))
    }
}
