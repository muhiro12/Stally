import AppIntents
import Foundation
import StallyLibrary

struct TagEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tag")
    static let defaultQuery = TagEntityQuery()
    let id: UUID
    @Property(title: "Name")
    var name: String
    @Property(title: "Details")
    var details: String

    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)", subtitle: "\(details)") }

    @MainActor
    init(_ record: StallyLibrary.Tag) {
        id = record.uuid
        name = record.name
        details = ""
    }
}
