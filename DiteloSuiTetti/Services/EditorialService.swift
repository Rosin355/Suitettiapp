import Foundation

// MARK: - Protocol

protocol EditorialServiceProtocol: Sendable {
    func fetchAll() async throws -> [Article]
    func fetchDelta(since date: Date) async throws -> [Article]
}

// MARK: - Stub (previews)

struct StubEditorialService: EditorialServiceProtocol {
    func fetchAll() async throws -> [Article] { Article.all }
    func fetchDelta(since date: Date) async throws -> [Article] { [] }
}

// MARK: - Live

struct LiveEditorialService: EditorialServiceProtocol {
    func fetchAll() async throws -> [Article] {
        let response: EditorialSyncResponseDTO = try await APIClient.fetch(AppEnvironment.syncEditorialEndpoint)
        return response.articles.map { $0.toArticle() }
    }

    func fetchDelta(since date: Date) async throws -> [Article] {
        let response: EditorialSyncResponseDTO = try await APIClient.fetch(
            AppEnvironment.syncEditorialDeltaEndpoint(since: date)
        )
        return response.articles.map { $0.toArticle() }
    }
}

