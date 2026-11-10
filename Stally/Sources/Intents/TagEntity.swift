import AppIntents
import Foundation
import StallyLibrary

struct TagEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tag")
    static let defaultQuery = TagEntityQuery()
    let id: UUID
    @Property(title: "Name")
    var name: String

    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)") }

    @MainActor
    init(_ record: StallyLibrary.Tag) {
        id = record.uuid
        name = record.name
    }
}
