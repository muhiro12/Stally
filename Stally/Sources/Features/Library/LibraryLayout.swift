import SwiftUI

enum LibraryLayout {
    static var primaryActionPlacement: ToolbarItemPlacement {
        #if os(iOS) || os(visionOS)
        .topBarPinnedTrailing
        #else
        .primaryAction
        #endif
    }

    static let minimumControlSize: CGFloat = 44
    static let editorPhotoHeight: CGFloat = 160
    static let detailPhotoHeight: CGFloat = 240
    static let previewLines = 2
    static let noteLines = 4...10
}
