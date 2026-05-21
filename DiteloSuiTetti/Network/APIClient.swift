import Foundation

/// Thin URLSession wrapper used by all Services.
/// Extend this with auth headers (Supabase anon key) once the key is available.
enum APIClient {

    // MARK: - Errors

    enum APIError: LocalizedError {
        case badStatus(Int)
        case noData

        var errorDescription: String? {
            switch self {
            case .badStatus(let code): return "Server returned status \(code)."
            case .noData:              return "The server returned an empty response."
            }
        }
    }

    // MARK: - Requests

    static func fetch<T: Decodable>(_ url: URL, as type: T.Type = T.self) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw APIError.noData }
        guard (200..<300).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
        return try JSONDecoder.editorial.decode(T.self, from: data)
    }
}

// MARK: - Shared decoder

private extension JSONDecoder {
    static let editorial: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: string) { return date }
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Unsupported date format: \(string)")
        }
        return d
    }()
}
