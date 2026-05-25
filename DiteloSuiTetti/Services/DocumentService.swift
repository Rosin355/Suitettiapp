import Foundation

// MARK: - Protocol

protocol DocumentServiceProtocol: Sendable {
    func fetchAll() async throws -> [Document]
}

// MARK: - Stub (previews)

struct StubDocumentService: DocumentServiceProtocol {
    func fetchAll() async throws -> [Document] { Document.all }
}

// MARK: - Live

struct LiveDocumentService: DocumentServiceProtocol {
    func fetchAll() async throws -> [Document] {
        let response: EditorialSyncResponseDTO = try await APIClient.fetch(AppEnvironment.syncEditorialEndpoint)
        return response.documents.map { $0.toDocument() }
    }
}

