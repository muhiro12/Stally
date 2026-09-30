#if DEBUG
import Foundation

enum StallyTrackingPreviewScreen: String {
    case yearDetail
    case monthDetail
    case archivedDetail
    case editYear
    case editMonth

    var itemID: UUID {
        switch self {
        case .yearDetail, .editYear:
            StallyFixtureItem.home.id
        case .monthDetail, .editMonth:
            StallyFixtureItem.windowPlant.id
        case .archivedDetail:
            StallyFixtureItem.archivedPlant.id
        }
    }

    var showsEditor: Bool {
        self == .editYear || self == .editMonth
    }
}

#endif
