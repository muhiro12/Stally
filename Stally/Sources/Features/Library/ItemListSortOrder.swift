import Foundation
import StallyLibrary

enum ItemListSortOrder: CaseIterable, Hashable {
    case newest
    case oldest
    case recentlyMarked
    case name

    var title: LocalizedStringResource {
        switch self {
        case .newest:
            "Newest First"
        case .oldest:
            "Oldest First"
        case .recentlyMarked:
            "Recently Marked"
        case .name:
            "Name"
        }
    }

    func matching(_ items: [Item], query: ItemQuery) -> [Item] {
        var query = query
        switch self {
        case .newest, .recentlyMarked:
            query.order = .newest
        case .oldest:
            query.order = .oldest
        case .name:
            query.order = .name
        }
        let matches = query.matching(items)
        guard self == .recentlyMarked else {
            return matches
        }

        // The stable sort retains newest-Item order for equal or missing Marks.
        return matches.map { item in
            let latest = item.marks?.lazy.map { ($0.localDateTime, $0.createdAt) }.max(by: <)
            return (item: item, latest: latest)
        }
        .sorted { first, second in
            switch (first.latest, second.latest) {
            case let (first?, second?):
                first > second
            case (_?, nil):
                true
            default:
                false
            }
        }
        .map(\.item)
    }
}
