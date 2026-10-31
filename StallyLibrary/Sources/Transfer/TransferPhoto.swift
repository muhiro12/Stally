import Foundation

struct TransferPhoto: Codable, Equatable, Sendable {
    var uuid: UUID
    var itemUUID: UUID
    var caption: String
    var sortOrder: Int
    var createdAt: Date
    var image: TransferImage
}
