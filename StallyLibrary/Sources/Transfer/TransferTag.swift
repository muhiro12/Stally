import Foundation

struct TransferTag: Codable, Equatable, Sendable {
    @TransferUUID var uuid: UUID
    var name: String
}
