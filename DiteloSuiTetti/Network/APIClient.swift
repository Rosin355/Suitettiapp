import Foundation

enum APIClient {

    // MARK: - Public API

    static func fetch<T: Decodable>(_ url: URL, as type: T.Type = T.self) async throws -> T {
        let request = makeRequest(url: url)
        return try await fetchWithRetry(request, as: type, attempt: 0)
    }

    // MARK: - Request building

    private static func makeRequest(url: URL) -> URLRequest {
        var r = URLRequest(url: url, timeoutInterval: 20)
        r.httpMethod = "GET"
        r.setValue("application/json", forHTTPHeaderField: "Accept")
        r.setValue("DiteloSuiTetti-iOS/1.0", forHTTPHeaderField: "User-Agent")
        return r
    }

    // MARK: - Retry wrapper

    private static let maxRetries = 2

    private static func fetchWithRetry<T: Decodable>(
        _ request: URLRequest, as type: T.Type, attempt: Int
    ) async throws -> T {
        do {
            return try await perform(request, as: type)
        } catch {
            if Task.isCancelled { throw APIError.cancelled }
            guard isRetryable(error), attempt < maxRetries else { throw error }
            let delayNs: UInt64 = attempt == 0 ? 500_000_000 : 1_000_000_000
            let delaySec = attempt == 0 ? "0.5" : "1.0"
            NSLog("[APIClient] ↺ retry %d/%d in %@s — %@", attempt + 1, maxRetries, delaySec, error.localizedDescription)
            try await Task.sleep(nanoseconds: delayNs)
            if Task.isCancelled { throw APIError.cancelled }
            return try await fetchWithRetry(request, as: type, attempt: attempt + 1)
        }
    }

    // MARK: - Single attempt

    private static func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        NSLog("[APIClient] ▶ %@ %@", request.httpMethod ?? "GET", request.url?.absoluteString ?? "-")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            throw classify(urlError)
        } catch {
            if Task.isCancelled { throw APIError.cancelled }
            throw APIError.transportFailed(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        NSLog("[APIClient] ← HTTP %d (%d bytes) from %@", http.statusCode, data.count, request.url?.host ?? "-")

        guard !data.isEmpty else { throw APIError.emptyResponse }
        guard (200..<300).contains(http.statusCode) else {
            let msg = serverErrorMessage(data)
            NSLog("[APIClient] ✗ bad status %d — %@", http.statusCode, msg ?? "(no body)")
            throw APIError.badStatus(code: http.statusCode, message: msg)
        }

        do {
            return try JSONDecoder.editorial.decode(T.self, from: data)
        } catch {
            let preview = String(data: data.prefix(1000), encoding: .utf8) ?? "<non-utf8>"
            NSLog("[APIClient] ✗ decode failed for %@: %@", String(describing: T.self), "\(error)")
            NSLog("[APIClient] ✗ raw body (first 1000 chars): %@", preview)
            SyncLogger.shared.append("DECODE FAIL [\(T.self)]: \(error)\nBody: \(preview)")
            throw APIError.decodingFailed(error)
        }
    }

    // MARK: - Helpers

    private static func classify(_ error: URLError) -> APIError {
        switch error.code {
        case .cancelled:
            return .cancelled
        case .timedOut:
            return .timedOut
        case .notConnectedToInternet,
             .networkConnectionLost,
             .cannotConnectToHost,
             .cannotFindHost,
             .dnsLookupFailed:
            return .offline
        default:
            return .transportFailed(error)
        }
    }

    private static func serverErrorMessage(_ data: Data) -> String? {
        if let json = try? JSONDecoder().decode(ServerErrorDTO.self, from: data) {
            return json.message ?? json.error ?? json.details
        }
        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text?.isEmpty == false ? text : nil
    }

    private static func isRetryable(_ error: Error) -> Bool {
        guard let apiError = error as? APIError else { return false }
        switch apiError {
        case .offline, .timedOut, .transportFailed:      return true
        case .badStatus(let code, _) where code >= 500:  return true
        default:                                          return false
        }
    }
}

// MARK: - Error types

extension APIClient {
    enum APIError: LocalizedError {
        case invalidResponse
        case badStatus(code: Int, message: String?)
        case emptyResponse
        case decodingFailed(Error)
        case transportFailed(Error)
        case timedOut
        case offline
        case cancelled

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Risposta non valida dal server."
            case .badStatus(let code, let msg):
                if let msg { return "Il server ha risposto con errore \(code): \(msg)." }
                return "Il server ha risposto con errore \(code)."
            case .emptyResponse:
                return "Il server ha restituito una risposta vuota."
            case .decodingFailed:
                return "Impossibile leggere i dati ricevuti dal server."
            case .transportFailed:
                return "Errore di rete. Verifica la connessione e riprova."
            case .timedOut:
                return "La richiesta ha impiegato troppo tempo. Riprova tra poco."
            case .offline:
                return "Connessione assente. Mostriamo i contenuti salvati quando disponibili."
            case .cancelled:
                return "Richiesta annullata."
            }
        }
    }
}

// MARK: - Private types

private struct ServerErrorDTO: Decodable {
    let error: String?
    let message: String?
    let details: String?
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

            // date-only "yyyy-MM-dd" (e.g. Supabase date columns)
            let dateOnly = DateFormatter()
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            dateOnly.dateFormat = "yyyy-MM-dd"
            dateOnly.timeZone = TimeZone(identifier: "UTC")
            if let date = dateOnly.date(from: string) { return date }

            NSLog("[APIClient] ✗ unsupported date string '%@' — decoder will throw", string)
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Unsupported date format: \(string)")
        }
        return d
    }()
}
