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

// MARK: - Mapping

private let uploadedFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "it_IT")
    f.dateFormat = "d MMM yyyy"
    return f
}()

private extension DocumentDTO {
    func toDocument() -> Document {
        Document(
            id: id,
            title: titolo,
            slug: slug,
            type: tipo,
            category: categoria,
            description: descrizione,
            url: url.flatMap { URL(string: $0) },
            uploadedAt: uploadedFormatter.string(from: dataCaricamento),
            updatedAt: updatedAt,
            syncVersion: syncVersion
        )
    }
}
