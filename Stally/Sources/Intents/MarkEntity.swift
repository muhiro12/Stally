import AppIntents
import Foundation
import StallyLibrary

struct MarkEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Mark")
    static let defaultQuery = MarkEntityQuery()
    let id: UUID
    @Property(title: "Item")
    var item: ItemEntity?
    @Property(title: "Date (YYYY-MM-DD or YYYY-MM-DDTHH:mm)")
    var localDateTime: String

    var displayRepresentation: DisplayRepresentation {
        .init(title: "\(item?.name ?? "")", subtitle: "\(localDateTime)")
    }

    @MainActor
    init(_ record: ItemMark) {
        id = record.uuid
        item = record.item.map(ItemEntity.init)
        localDateTime = record.localDateTime
    }
}
