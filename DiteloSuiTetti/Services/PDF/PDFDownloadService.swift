import Foundation

enum PDFDownloadError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:         return "URL del documento non valido."
        case .httpError(let c):   return "Errore del server (codice \(c))."
        case .invalidContent:     return "Il file scaricato non è un PDF valido."
        }
    }
}

actor PDFDownloadService {
    static let shared = PDFDownloadService()
    private init() {}

    private var cache: [URL: URL] = [:]
    private var inflight: [URL: Task<URL, Error>] = [:]

    func localURL(for remoteURL: URL) async throws -> URL {
        if let local = cache[remoteURL], FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        if let task = inflight[remoteURL] {
            return try await task.value
        }
        let task = Task { try await Self.download(remoteURL) }
        inflight[remoteURL] = task
        do {
            let url = try await task.value
            cache[remoteURL] = url
            inflight.removeValue(forKey: remoteURL)
            return url
        } catch {
            inflight.removeValue(forKey: remoteURL)
            throw error
        }
    }

    private static func download(_ remoteURL: URL) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            try? FileManager.default.removeItem(at: tempURL)
            throw PDFDownloadError.httpError(http.statusCode)
        }

        let isPDF: Bool
        if let http = response as? HTTPURLResponse, let mime = http.mimeType {
            isPDF = mime.contains("pdf") || remoteURL.pathExtension.lowercased() == "pdf"
        } else {
            isPDF = remoteURL.pathExtension.lowercased() == "pdf"
        }

        guard isPDF else {
            try? FileManager.default.removeItem(at: tempURL)
            throw PDFDownloadError.invalidContent
        }

        let name = remoteURL.lastPathComponent.isEmpty
            ? UUID().uuidString + ".pdf"
            : remoteURL.lastPathComponent
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }
}
