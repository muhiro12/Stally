#if DEBUG
enum StallyTrackingPreviewScreen: String {
    case yearDetail
    case monthDetail
    case archivedDetail
    case editYear
    case editMonth

    var itemName: String {
        switch self {
        case .yearDetail, .editYear:
            "Home"
        case .monthDetail, .editMonth:
            "Window Plant"
        case .archivedDetail:
            "Archived Plant"
        }
    }

    var showsEditor: Bool {
        self == .editYear || self == .editMonth
    }
}

#endif
