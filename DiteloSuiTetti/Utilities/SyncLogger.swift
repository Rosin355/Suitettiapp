import Foundation

/// Thread-safe in-process log sink for sync diagnostics.
///
/// - `append` is nonisolated — callable from any thread/actor context.
/// - Every entry is written to NSLog (visible in Console.app and device logs from TestFlight).
/// - The last 50 entries are kept in `entries` for the in-app diagnostic overlay.
@Observable
@MainActor
final class SyncLogger {
    static let shared = SyncLogger()

    // nonisolated init so the static let above can be initialised from any context
    nonisolated init() {}

    private(set) var entries: [String] = []
    private(set) var lastArticleCount: Int = 0
    private(set) var lastEventCount:   Int = 0
    private(set) var lastDocumentCount: Int = 0

    /// Append a message from any context. NSLog is called synchronously on the calling thread;
    /// the ring buffer is updated on the main actor.
    nonisolated func append(_ message: String) {
        let entry = "[\(isoNow())] \(message)"
        NSLog("[SyncLog] %@", entry)
        Task { @MainActor [weak self] in
            guard let self else { return }
            entries.append(entry)
            if entries.count > 50 { entries.removeFirst() }
        }
    }

    @MainActor
    func recordSyncResult(articles: Int, events: Int, documents: Int) {
        lastArticleCount   = articles
        lastEventCount     = events
        lastDocumentCount  = documents
    }

    @MainActor func clear() { entries.removeAll() }

    nonisolated private func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
