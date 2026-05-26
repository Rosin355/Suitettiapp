import SwiftUI

@MainActor
@Observable
final class ArticleStore {

    // MARK: - State

    private(set) var articles: [Article] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?
    private(set) var offlineMessage: String?

    var categories: [String] {
        let unique = articles.map(\.category).reduce(into: [String]()) {
            if !$0.contains($1) { $0.append($1) }
        }
        return ["Tutto"] + unique
    }

    // MARK: - Init

    private let service: any EditorialServiceProtocol

    init(service: any EditorialServiceProtocol = LiveEditorialService()) {
        self.service = service
    }

    // MARK: - Actions

    func load() async {
        guard !isLoading, !isRefreshing, articles.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            articles = try await service.fetchAll()
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
            articles = try await service.fetchAll()
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

    func replace(with articles: [Article]) {
        self.articles = articles
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
