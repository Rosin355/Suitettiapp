import SwiftUI
import PDFKit

struct PDFReaderView: View {
    let remoteURL: URL
    let title: String

    @State private var pdfDocument: PDFDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let doc = pdfDocument {
                PDFKitView(document: doc)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                errorView
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(.brandCream)
        .toolbar {
            if let doc = pdfDocument, let localURL = doc.documentURL {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: localURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Condividi PDF")
                }
            }
        }
        .task { await loadPDF() }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Caricamento PDF…")
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.brandGrayLight)
            Text(errorMessage ?? "Impossibile caricare il PDF.")
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Riprova") {
                Task { await loadPDF() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandRed)
            .accessibilityLabel("Riprova il caricamento del PDF")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadPDF() async {
        NSLog("[DocumentURL] title=%@ url=%@", title, remoteURL.absoluteString)
        isLoading = true
        errorMessage = nil
        pdfDocument = nil
        do {
            let localURL = try await PDFDownloadService.shared.localURL(for: remoteURL)
            guard let doc = PDFDocument(url: localURL) else {
                errorMessage = "Il file scaricato non è un PDF valido."
                isLoading = false
                return
            }
            pdfDocument = doc
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
