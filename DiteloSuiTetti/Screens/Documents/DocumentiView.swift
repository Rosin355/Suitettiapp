import SwiftUI

struct DocumentiView: View {
    @Environment(DocumentStore.self) private var store

    var body: some View {
        Group {
            if store.isLoading {
                loadingView
            } else if let message = store.errorMessage {
                errorView(message: message)
            } else if store.documents.isEmpty {
                emptyView
            } else {
                documentList
            }
        }
        .task { await store.load() }
        .refreshable { await store.refresh() }
    }

    // MARK: - States

    private var documentList: some View {
        ScrollView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white.opacity(0.8))
                    .frame(height: 1)

                ForEach(Array(store.documents.enumerated()), id: \.element.id) { index, doc in
                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                        DocumentListRow(document: doc, isLast: index == store.documents.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.white.opacity(0.82))
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
            .padding(.horizontal, DT.padding)
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Caricamento documenti…")
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(.brandGrayLight)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Riprova") {
                Task { await store.refresh() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandRed)
            .accessibilityLabel("Riprova il caricamento dei documenti")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 40))
                .foregroundStyle(.brandGrayLight)
            Text("Nessun documento disponibile.")
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        DocumentiView()
            .navigationTitle("Documenti")
    }
    .environment(DocumentStore(service: StubDocumentService()))
}
