import AppIntents
import Foundation
import StallyLibrary

struct MarkEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Mark")
    static let defaultQuery = MarkEntityQuery()
    let id: UUID
    @Property(title: "Name")
    var name: String
    @Property(title: "Details")
    var details: String

    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)", subtitle: "\(details)") }

    @MainActor
    init(_ record: ItemMark) {
        id = record.uuid
        name = record.item?.name ?? ""
        details = record.localDateTime
    }
}
