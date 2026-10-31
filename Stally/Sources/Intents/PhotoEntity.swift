import AppIntents
import Foundation
import StallyLibrary

struct PhotoEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Photo")
    static let defaultQuery = PhotoEntityQuery()
    let id: UUID
    @Property(title: "Name")
    var name: String
    @Property(title: "Details")
    var details: String

    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)", subtitle: "\(details)") }

    @MainActor
    init(_ record: ItemPhoto) {
        id = record.uuid
        name = record.item?.name ?? ""
        details = record.caption
    }
}
