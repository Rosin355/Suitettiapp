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
            apply(try await service.fetchAll())
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
            apply(try await service.fetchAll())
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
        apply(articles)
        isLoading = false
        isRefreshing = false
        offlineMessage = nil
    }

    /// Single choke point: every path that sets `articles` (live sync, cache
    /// restore, service fetch, pull-to-refresh) routes through here so the list
    /// is always newest-first and never trusts backend array order.
    private func apply(_ incoming: [Article]) {
        articles = EditorialSort.articlesByDateDescending(incoming)
        let hasGrazie = articles.contains { $0.title == "Grazie!!" }
        NSLog("[ArticleStore] final count=%d", articles.count)
        NSLog("[ArticleStore] contains Grazie=%@", hasGrazie ? "true" : "false")
        if let latest = articles.first {
            NSLog("[ArticleStore] sorted latest article: '%@' (%@)", latest.title, latest.fullDate)
        }
        #if DEBUG
        for (i, a) in articles.prefix(10).enumerated() {
            NSLog("[ArticleStore] [%d] %@ | %@", i, a.title, a.fullDate)
        }
        #endif
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
