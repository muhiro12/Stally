import AppIntents
import Foundation
import StallyLibrary

struct PhotoEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Photo")
    static let defaultQuery = PhotoEntityQuery()
    let id: UUID
    @Property(title: "Item")
    var item: ItemEntity?
    @Property(title: "Caption")
    var caption: String?

    var displayRepresentation: DisplayRepresentation {
        .init(title: "\(item?.name ?? "")", subtitle: "\(caption ?? "")")
    }

    @MainActor
    init(_ record: ItemPhoto) {
        id = record.uuid
        item = record.item.map(ItemEntity.init)
        caption = record.caption
    }
}
