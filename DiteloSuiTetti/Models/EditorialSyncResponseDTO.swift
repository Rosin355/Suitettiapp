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

        // MARK: Articles — per-item lossy so one bad record never kills the whole section
        if let lossyArts = try? c.decode([Lossy<ArticleDTO>].self, forKey: .articles) {
            let good = lossyArts.compactMap(\.value)
            let bad  = lossyArts.count - good.count
            if bad > 0 {
                NSLog("[EditorialSyncResponseDTO] ⚠️ %d/%d articles failed per-item decode",
                      bad, lossyArts.count)
                lossyArts.enumerated()
                    .filter { $0.element.value == nil }
                    .prefix(5)
                    .forEach { i, lossy in
                        if let e = lossy.decodeError {
                            NSLog("[EditorialSyncResponseDTO] ✗ article[%d] error: %@", i, "\(e)")
                        }
                    }
                SyncLogger.shared.append("articles: \(good.count) OK, \(bad) failed per-item")
            }
            NSLog("[EditorialSyncResponseDTO] articles decoded: %d", good.count)
            if let first = good.first {
                let firstAtt = first.attachments.first?.title ?? "none"
                NSLog("[EditorialSyncResponseDTO] first article: title='%@' attachments=%d firstAtt='%@'",
                      first.titolo, first.attachments.count, firstAtt)
            }
            articles = good
        } else {
            articles = []
            let keyPresent = c.contains(.articles)
            NSLog("[EditorialSyncResponseDTO] ✗ articles top-level decode failed — key present: %@",
                  keyPresent ? "yes (wrong type?)" : "no")
            SyncLogger.shared.append("articles section: decode failed, key present=\(keyPresent)")
        }

        // MARK: Events — per-item lossy
        if let lossyEvts = try? c.decode([Lossy<EventDTO>].self, forKey: .events) {
            let good = lossyEvts.compactMap(\.value)
            let bad  = lossyEvts.count - good.count
            if bad > 0 {
                NSLog("[EditorialSyncResponseDTO] ⚠️ %d/%d events failed per-item decode",
                      bad, lossyEvts.count)
                lossyEvts.enumerated()
                    .filter { $0.element.value == nil }
                    .prefix(5)
                    .forEach { i, lossy in
                        if let e = lossy.decodeError {
                            NSLog("[EditorialSyncResponseDTO] ✗ event[%d] error: %@", i, "\(e)")
                        }
                    }
                SyncLogger.shared.append("events: \(good.count) OK, \(bad) failed per-item")
            }
            NSLog("[EditorialSyncResponseDTO] events decoded: %d", good.count)
            if let first = good.first {
                NSLog("[EditorialSyncResponseDTO] first event: title='%@' attachments=%d",
                      first.titolo, first.attachments.count)
            }
            events = good
        } else {
            events = []
            let keyPresent = c.contains(.events)
            NSLog("[EditorialSyncResponseDTO] ✗ events top-level decode failed — key present: %@",
                  keyPresent ? "yes (wrong type?)" : "no")
            SyncLogger.shared.append("events section: decode failed, key present=\(keyPresent)")
        }

        // MARK: Documents — per-item lossy (unchanged)
        if let lossyDocs = try? c.decode([Lossy<DocumentDTO>].self, forKey: .documents) {
            let good = lossyDocs.compactMap(\.value)
            let bad  = lossyDocs.count - good.count
            if bad > 0 {
                NSLog("[EditorialSyncResponseDTO] ⚠️ %d/%d documents failed per-item decode",
                      bad, lossyDocs.count)
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
            documents = []
            NSLog("[EditorialSyncResponseDTO] ⚠️ documents key missing or wrong type — 0 documents")
            SyncLogger.shared.append("documents section: key missing or wrong type")
        }
    }
}

// MARK: - Lossy per-item wrapper

/// Wraps T so that [Lossy<T>] array decoding never throws.
/// Each element either decodes successfully or is captured as nil with its error.
/// Internal access so ArticleDTO / EventDTO can use Lossy<AttachmentDTO>.
struct Lossy<T: Decodable>: Decodable {
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
