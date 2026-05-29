import Foundation

struct EditorialSyncResponseDTO: Decodable {
    let serverTime: Date
    let articles:   [ArticleDTO]
    let events:     [EventDTO]
    let documents:  [DocumentDTO]

    private enum CodingKeys: String, CodingKey {
        case serverTime, articles, events, documents
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        serverTime = (try? c.decode(Date.self, forKey: .serverTime)) ?? Date()

        if let arts = try? c.decode([ArticleDTO].self, forKey: .articles) {
            articles = arts
        } else {
            articles = []
            NSLog("[EditorialSyncResponseDTO] ⚠️ articles section failed to decode — returning empty")
        }

        if let evts = try? c.decode([EventDTO].self, forKey: .events) {
            events = evts
        } else {
            events = []
            NSLog("[EditorialSyncResponseDTO] ⚠️ events section failed to decode — returning empty")
        }

        // Decode documents per-item so one bad record never kills the whole array.
        // Lossy<DocumentDTO> always succeeds; items that throw are captured as nil.
        if let lossyDocs = try? c.decode([Lossy<DocumentDTO>].self, forKey: .documents) {
            let good = lossyDocs.compactMap(\.value)
            let bad  = lossyDocs.count - good.count
            if bad > 0 {
                NSLog("[EditorialSyncResponseDTO] ⚠️ %d/%d documents failed per-item decode",
                      bad, lossyDocs.count)
                // Log the first two per-item errors for diagnostics
                lossyDocs.prefix(5).filter { $0.value == nil }.prefix(2).forEach { lossy in
                    if let e = lossy.decodeError {
                        NSLog("[EditorialSyncResponseDTO] ✗ document item error: %@", "\(e)")
                    }
                }
                SyncLogger.shared.append("documents: \(good.count) OK, \(bad) failed per-item")
            }
            NSLog("[EditorialSyncResponseDTO] documents decoded: %d", good.count)
            documents = good
        } else {
            // Key missing or wrong top-level type — log raw section for diagnostics
            documents = []
            NSLog("[EditorialSyncResponseDTO] ⚠️ documents key missing or wrong type — 0 documents")
            SyncLogger.shared.append("documents section: key missing or wrong type")
        }
    }
}

// MARK: - Per-item lossy wrapper

/// Wraps T so that [Lossy<T>] array decoding never throws.
/// Each element either decodes to value or is captured as nil with its error.
private struct Lossy<T: Decodable>: Decodable {
    let value: T?
    let decodeError: (any Error)?

    init(from decoder: Decoder) throws {
        do {
            value = try T(from: decoder)
            decodeError = nil
        } catch {
            value = nil
            decodeError = error
        }
    }
}
