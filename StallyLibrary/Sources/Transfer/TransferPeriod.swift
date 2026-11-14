import Foundation

struct TransferPeriod: Codable, Equatable, Sendable {
    @TransferUUID var uuid: UUID
    @TransferUUID var itemUUID: UUID
    @TransferNullable var startLocalDate: String?
    @TransferNullable var endLocalDate: String?
    var isOngoing: Bool
    var createdAt: Date
}
