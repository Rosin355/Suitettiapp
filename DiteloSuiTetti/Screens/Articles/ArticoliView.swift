import SwiftUI

struct ArticoliView: View {
    @Environment(ArticleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedCategory = "Tutto"
    @State private var selectedArticle: Article? = nil
    @State private var refreshHaptic = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isIPad: Bool { horizontalSizeClass == .regular }

    private var filtered: [Article] {
        selectedCategory == "Tutto"
            ? store.articles
            : store.articles.filter { $0.category == selectedCategory }
    }

    var body: some View {
        Group {
            if store.isLoading && store.articles.isEmpty {
                loadingView
            } else if let errorMessage = store.errorMessage, store.articles.isEmpty {
                EmptyStateView(
                    icon: "wifi.slash",
                    title: "Errore di caricamento",
                    subtitle: errorMessage,
                    iconTint: .brandGray,
                    primaryLabel: "Riprova",
                    primaryAction: { Task { await store.load() } }
                )
                .background(.brandCream)
            } else if store.articles.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "Nessun articolo",
                    subtitle: "Non sono presenti articoli al momento."
                )
                .background(.brandCream)
            } else if isIPad {
                iPadSplitLayout
            } else {
                iPhoneLayout
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.brandCream, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .task { await store.load() }
        .onChange(of: store.categories) { _, newCategories in
            if !newCategories.contains(selectedCategory) {
                selectedCategory = "Tutto"
            }
        }
        .sensoryFeedback(.success, trigger: refreshHaptic)
    }

    // MARK: - iPhone layout (NavigationLink + zoom transitions)

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            offlineBadge
            // Filter bar sits OUTSIDE the ScrollView so the horizontal scroll gesture
            // is never nested inside a vertical scroll — prevents tap interception.
            ArticlesFilterBar(selectedCategory: $selectedCategory,
                              categories: store.categories)
                .padding(.top, 4)
                .padding(.bottom, 8)
            ScrollView {
                ArticlesListSection(
                    filtered: filtered,
                    showFeatured: selectedCategory == "Tutto"
                )
            }
            .scrollIndicators(.hidden)
            .background(.brandCream)
            .refreshable {
                await store.refresh()
                refreshHaptic.toggle()
            }
        }
        .background(.brandCream)
        .appearAnimation()
    }

    // MARK: - iPad two-column split layout

    private var iPadSplitLayout: some View {
        GeometryReader { geo in
            let leftWidth = max(280, min(400, geo.size.width * 0.40))
            HStack(spacing: 0) {
                // Left: filter bar + scrollable article list
                VStack(spacing: 0) {
                    offlineBadge
                    ArticlesFilterBar(selectedCategory: $selectedCategory,
                                      categories: store.categories)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    ScrollView {
                        ArticlesListSection(
                            filtered: filtered,
                            showFeatured: selectedCategory == "Tutto",
                            onSelect: { article in
                                if reduceMotion {
                                    selectedArticle = article
                                } else {
                                    withAnimation(.spring(duration: 0.3)) {
                                        selectedArticle = article
                                    }
                                }
                            },
                            selectedArticle: selectedArticle
                        )
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await store.refresh()
                        refreshHaptic.toggle()
                    }
                }
                .frame(width: leftWidth)
                .background(.brandCream)

                Divider()

                // Right: article detail or placeholder
                Group {
                    if let article = selectedArticle {
                        ArticleDetailView(article: article, isEmbedded: true)
                            .id(article.id)
                            .transition(reduceMotion ? .opacity : .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else {
                        iPadDetailPlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
                .background(.brandCream)
            }
            .appearAnimation()
            .onAppear {
                if selectedArticle == nil {
                    selectedArticle = filtered.first
                }
            }
            .onChange(of: filtered.map(\.id)) { _, newIDs in
                if let current = selectedArticle, !newIDs.contains(current.id) {
                    selectedArticle = filtered.first
                }
            }
        }
    }

    // MARK: - Shared sub-views

    @ViewBuilder
    private var offlineBadge: some View {
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
    }

    private var loadingView: some View {
        ScrollView {
            SkeletonLoadingList()
                .padding(.top, 16)
        }
        .scrollIndicators(.hidden)
        .background(.brandCream)
    }

    private var iPadDetailPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 40))
                .foregroundStyle(.brandGrayLight)
            Text("Seleziona un articolo")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.brandGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.brandCream)
    }
}

#Preview("iPhone – Light") {
    NavigationStack {
        ArticoliView()
            .navigationTitle("Articoli")
            .environment(ArticleStore(service: StubEditorialService()))
    }
}

#Preview("iPhone – Dark") {
    NavigationStack {
        ArticoliView()
            .navigationTitle("Articoli")
            .environment(ArticleStore(service: StubEditorialService()))
    }
    .preferredColorScheme(.dark)
}

#Preview("iPad split") {
    NavigationStack {
        ArticoliView()
            .navigationTitle("Articoli")
            .environment(ArticleStore(service: StubEditorialService()))
    }
    .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
    .previewDisplayName("iPad Pro 13\"")
}
