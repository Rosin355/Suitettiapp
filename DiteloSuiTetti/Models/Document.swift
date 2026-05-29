import Foundation

struct Document: Identifiable {
    let id: UUID
    let title: String
    let slug: String
    let type: String
    let category: String
    let description: String
    let url: URL?
    let uploadedAt: String
    let updatedAt: Date?
    let syncVersion: Int
}
