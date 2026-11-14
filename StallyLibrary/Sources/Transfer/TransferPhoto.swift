import Foundation

struct TransferPhoto: Codable, Equatable, Sendable {
    @TransferUUID var uuid: UUID
    @TransferUUID var itemUUID: UUID
    @TransferNullable var caption: String?
    var sortOrder: Int
    var createdAt: Date
    var image: TransferImage
}
