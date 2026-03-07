import Foundation

/// Search, filter, and sort state shared by Stally item lists.
public struct ItemListQuery: Equatable, Sendable {
    public enum ListKind: Sendable {
        case active
        case archived
    }

    public enum SortOption: String, CaseIterable, Equatable, Sendable {
        case defaultOrder
        case recentlyMarked
        case mostMarked
        case name

        public var title: String {
            switch self {
            case .defaultOrder:
                "Default Order"
            case .recentlyMarked:
                "Recently Marked"
            case .mostMarked:
                "Most Marked"
            case .name:
                "Name"
            }
        }
    }

    public var searchText: String
    public var category: ItemCategory?
    public var sortOption: SortOption

    public init(
        searchText: String = "",
        category: ItemCategory? = nil,
        sortOption: SortOption = .defaultOrder
    ) {
        self.searchText = searchText
        self.category = category
        self.sortOption = sortOption
    }

    public var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var hasRefinements: Bool {
        !trimmedSearchText.isEmpty
            || category != nil
            || sortOption != .defaultOrder
    }
}
