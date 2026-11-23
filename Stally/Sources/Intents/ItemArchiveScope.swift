import AppIntents
import StallyLibrary

enum ItemArchiveScope: String, AppEnum {
    case library
    case archived
    case all

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Library Scope")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .library: "Library", .archived: "Archive", .all: "All Items"
    ]

    var queryScope: ItemQuery.ArchiveScope {
        switch self {
        case .library:
            .library
        case .archived:
            .archived
        case .all:
            .all
        }
    }
}
