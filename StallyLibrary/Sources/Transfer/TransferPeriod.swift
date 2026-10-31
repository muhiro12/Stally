import Foundation

struct TransferPeriod: Codable, Equatable, Sendable {
    var uuid: UUID
    var itemUUID: UUID
    var startLocalDate: String?
    var endLocalDate: String?
    var isOngoing: Bool
    var createdAt: Date
}
