import Foundation

struct TransferManifest: Codable, Equatable, Sendable {
    var format: String
    var formatVersion: Int
    var schemaVersion: String
    var exportedAt: Date
    var items: [TransferItem]
    var itemMarks: [TransferMark]
    var itemPeriods: [TransferPeriod]
    var itemPhotos: [TransferPhoto]
    var tags: [TransferTag]
}
