import Foundation

/// Reversible query choices shared by the Library and system adapters.
public struct ItemQuery: Sendable {
    public enum ArchiveScope: String, CaseIterable, Sendable {
        case library
        case archived
        case all
    }

    public enum Order: String, CaseIterable, Sendable {
        case newest
        case oldest
        case name
    }

    public var text: String
    public var archiveScope = ArchiveScope.library
    public var favoritesOnly = false
    public var tagID: UUID?
    public var order = Order.newest

    public init() {
        text = ""
    }

    public func matching(_ items: [Item]) -> [Item] {
        items.filter { item in
            (archiveScope == .all || item.isArchived == (archiveScope == .archived))
                && (!favoritesOnly || item.isFavorite)
                && (tagID == nil || (item.tags ?? []).contains { $0.uuid == tagID })
                && (text.isEmpty || item.name.localizedStandardContains(text)
                        || item.note.localizedStandardContains(text)
                        || (item.tags ?? []).contains { $0.name.localizedStandardContains(text) })
        }
        .sorted { first, second in
            switch order {
            case .newest where first.createdAt != second.createdAt:
                return first.createdAt > second.createdAt
            case .oldest where first.createdAt != second.createdAt:
                return first.createdAt < second.createdAt
            case .name:
                let comparison = first.name.localizedStandardCompare(second.name)
                return comparison == .orderedSame ? first.uuid.uuidString < second.uuid.uuidString
                    : comparison == .orderedAscending
            default:
                return first.uuid.uuidString < second.uuid.uuidString
            }
        }
    }
}
