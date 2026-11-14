import Foundation

struct TransferItem: Codable, Equatable, Sendable {
    @TransferUUID var uuid: UUID
    var name: String
    @TransferNullable var note: String?
    @TransferNullable var representativeURL: String?
    var createdAt: Date
    var isArchived: Bool
    var isFavorite: Bool
    var isMarkRecordingEnabled: Bool
    @TransferUUIDs var tagUUIDs: [UUID]
}
