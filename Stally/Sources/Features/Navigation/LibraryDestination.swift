import StallyLibrary
import SwiftData
import SwiftUI

enum LibraryDestination: Hashable {
    case library
    case favorites
    case recording
    case archive
    case tag(PersistentIdentifier)

    static let collections: [Self] = [.library, .favorites, .recording, .archive]

    var title: LocalizedStringResource {
        switch self {
        case .library:
            "Library"
        case .favorites:
            "Favorites"
        case .recording:
            "Mark Recording"
        case .archive:
            "Archive"
        case .tag:
            "Tag"
        }
    }

    var symbol: String {
        switch self {
        case .library:
            "square.stack"
        case .favorites:
            "star"
        case .recording:
            "checkmark.circle"
        case .archive:
            "archivebox"
        case .tag:
            "tag"
        }
    }

    func includes(_ item: Item) -> Bool {
        switch self {
        case .library:
            true
        case .favorites:
            item.isFavorite
        case .recording:
            item.isMarkRecordingEnabled
        case .archive:
            true
        case .tag(let identifier):
            (item.tags ?? []).contains { tag in
                tag.persistentModelID == identifier
            }
        }
    }
}
