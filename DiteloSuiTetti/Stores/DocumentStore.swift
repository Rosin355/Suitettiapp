import Foundation

@MainActor
@Observable
final class DocumentStore {

    private(set) var documents: [Document] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?
    private(set) var offlineMessage: String?

    private let service: any DocumentServiceProtocol

    init(service: any DocumentServiceProtocol = LiveDocumentService()) {
        self.service = service
    }

    func load() async {
        guard !isLoading, !isRefreshing, documents.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            documents = try await service.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard !isLoading, !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }
        do {
            documents = try await service.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Coordinator support

    func beginLoading() {
        guard !isLoading, !isRefreshing else { return }
        isLoading = true
        errorMessage = nil
    }

    func replace(with documents: [Document]) {
        self.documents = documents
        isLoading = false
        isRefreshing = false
        offlineMessage = nil
    }

    func failedLoading(message: String) {
        errorMessage = message
        isLoading = false
        isRefreshing = false
    }

    func setOfflineWarning() {
        offlineMessage = "Contenuto non aggiornato — verifica la connessione."
    }
}
