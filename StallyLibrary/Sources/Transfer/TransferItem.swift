import Foundation

struct TransferItem: Codable, Equatable, Sendable {
    var uuid: UUID
    var name: String
    var note: String
    var representativeURL: String?
    var createdAt: Date
    var isArchived: Bool
    var isFavorite: Bool
    var isMarkRecordingEnabled: Bool
    var tagUUIDs: [UUID]
}
