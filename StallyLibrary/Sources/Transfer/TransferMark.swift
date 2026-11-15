import Foundation

struct TransferMark: Codable, Equatable, Sendable {
    @TransferUUID var uuid: UUID
    @TransferUUID var itemUUID: UUID
    var localDateTime: String
    var createdAt: Date
}
