import SwiftUI

struct DocumentiView: View {
    @Environment(DocumentStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var refreshHaptic = false

    var body: some View {
        Group {
            if store.isLoading {
                loadingView
            } else if let message = store.errorMessage {
                EmptyStateView(
                    icon: "wifi.slash",
                    title: "Connessione non disponibile",
                    subtitle: message,
                    iconTint: .brandGray,
                    primaryLabel: "Riprova",
                    primaryAction: { Task { await store.refresh() } }
                )
                .background(.brandCream)
            } else if store.documents.isEmpty {
                EmptyStateView(
                    icon: "doc.on.doc",
                    title: "Nessun documento",
                    subtitle: "Non sono presenti documenti al momento."
                )
                .background(.brandCream)
            } else {
                documentList
                    .appearAnimation()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.brandCream, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .task { await store.load() }
        .refreshable {
            await store.refresh()
            refreshHaptic.toggle()
        }
        .sensoryFeedback(.success, trigger: refreshHaptic)
    }

    // MARK: - Document list

    private var documentList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let msg = store.offlineMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash").font(.system(size: 12))
                        Text(msg).font(.system(size: 13))
                    }
                    .foregroundStyle(.brandGray)
                    .padding(.horizontal, DT.padding)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }

                Rectangle()
                    .fill(.white.opacity(0.8))
                    .frame(height: 1)

                ForEach(Array(store.documents.enumerated()), id: \.element.id) { index, doc in
                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                        DocumentListRow(document: doc, isLast: index == store.documents.count - 1)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .background(.white.opacity(0.82))
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
            // Constrain to readable width on iPad, center it
            .frame(maxWidth: horizontalSizeClass == .regular ? DT.readableMaxWidth : .infinity)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DT.padding)
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
        .background(.brandCream)
    }

    // MARK: - Loading

    private var loadingView: some View {
        ScrollView {
            SkeletonLoadingList()
                .frame(maxWidth: horizontalSizeClass == .regular ? DT.readableMaxWidth : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
        .scrollIndicators(.hidden)
        .background(.brandCream)
    }
}

#Preview("Documenti – Light") {
    NavigationStack {
        DocumentiView()
            .navigationTitle("Documenti")
    }
    .environment(DocumentStore(service: StubDocumentService()))
}

#Preview("Documenti – Dark") {
    NavigationStack {
        DocumentiView()
            .navigationTitle("Documenti")
    }
    .environment(DocumentStore(service: StubDocumentService()))
    .preferredColorScheme(.dark)
}
