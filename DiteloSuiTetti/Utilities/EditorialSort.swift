import Foundation

/// Single source of truth for editorial content ordering.
///
/// Content must always be shown newest-first by its publication/upload date,
/// regardless of the order the backend array happens to arrive in. Items without
/// a date are placed *after* all dated content, preserving their incoming
/// relative order so the result is deterministic.
enum EditorialSort {

    /// Articles newest-first by `publishedAt`; undated articles last.
    static func articlesByDateDescending(_ articles: [Article]) -> [Article] {
        byDateDescending(articles, key: \.publishedAt)
    }

    /// Documents newest-first by `publishedAt`; undated documents last.
    static func documentsByDateDescending(_ documents: [Document]) -> [Document] {
        byDateDescending(documents, key: \.publishedAt)
    }

    /// Stable descending sort by an optional `Date` key. `nil` dates sort last.
    /// Stability is guaranteed by using the original index as the tie-breaker,
    /// which `Array.sorted` does not provide on its own.
    private static func byDateDescending<T>(_ items: [T], key: KeyPath<T, Date?>) -> [T] {
        items.enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element[keyPath: key], rhs.element[keyPath: key]) {
                case let (l?, r?): return l == r ? lhs.offset < rhs.offset : l > r
                case (_?, nil):    return true          // dated before undated
                case (nil, _?):    return false
                case (nil, nil):   return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }
}
