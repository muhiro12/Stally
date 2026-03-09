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
                StallyLibraryLocalization.string("Default Order")
            case .recentlyMarked:
                StallyLibraryLocalization.string("Recently Marked")
            case .mostMarked:
                StallyLibraryLocalization.string("Most Marked")
            case .name:
                StallyLibraryLocalization.string("Name")
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
                StallyLibraryLocalization.string("Marked on Day")
            case .unmarkedOnReferenceDay:
                StallyLibraryLocalization.string("Open on Day")
            case .withHistory:
                StallyLibraryLocalization.string("With History")
            case .withoutHistory:
                StallyLibraryLocalization.string("Without History")
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
