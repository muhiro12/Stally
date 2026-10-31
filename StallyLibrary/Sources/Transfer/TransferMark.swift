import Foundation

struct TransferMark: Codable, Equatable, Sendable {
    var uuid: UUID
    var itemUUID: UUID
    var localDateTime: String
    var createdAt: Date
}
