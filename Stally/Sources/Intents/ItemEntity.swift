import AppIntents
import Foundation
import StallyLibrary

struct ItemEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Item")
    static let defaultQuery = ItemEntityQuery()
    let id: UUID
    @Property(title: "Name")
    var name: String
    @Property(title: "Details")
    var details: String

    @Property(title: "Representative URL")
    var link: String?
    @Property(title: "Archived")
    var archived: Bool
    @Property(title: "Favorite")
    var favorite: Bool
    @Property(title: "Recording Enabled")
    var recordingEnabled: Bool

    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)", subtitle: "\(details)") }

    @MainActor
    init(_ record: Item) {
        id = record.uuid
        name = record.name
        details = record.note
        link = record.representativeURL
        archived = record.isArchived
        favorite = record.isFavorite
        recordingEnabled = record.isMarkRecordingEnabled
    }
}
