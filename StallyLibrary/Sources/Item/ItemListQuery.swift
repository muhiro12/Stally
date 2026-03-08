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

    public enum QuickFilter: String, CaseIterable, Equatable, Sendable {
        case markedOnReferenceDay
        case unmarkedOnReferenceDay
        case withHistory
        case withoutHistory

        public var title: String {
            switch self {
            case .markedOnReferenceDay:
                "Marked on Day"
            case .unmarkedOnReferenceDay:
                "Open on Day"
            case .withHistory:
                "With History"
            case .withoutHistory:
                "Without History"
            }
        }
    }

    public var searchText: String
    public var category: ItemCategory?
    public var quickFilter: QuickFilter?
    public var sortOption: SortOption

    public var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var hasRefinements: Bool {
        !trimmedSearchText.isEmpty
            || category != nil
            || quickFilter != nil
            || sortOption != .defaultOrder
    }

    public init(
        searchText: String = "",
        category: ItemCategory? = nil,
        quickFilter: QuickFilter? = nil,
        sortOption: SortOption = .defaultOrder
    ) {
        self.searchText = searchText
        self.category = category
        self.quickFilter = quickFilter
        self.sortOption = sortOption
    }
}
