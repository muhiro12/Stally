#if DEBUG
import SwiftUI

#Preview("Item Detail - Non Mark Month") {
    StallyPreviewContainer(.timeTogether) { items in
        NavigationStack {
            if let item = items.first(where: { $0.name == "Window Plant" }) {
                ItemDetailView()
                    .environment(item)
            }
        }
    }
}

#Preview("Item Detail - Archived Day") {
    StallyPreviewContainer(.timeTogether) { items in
        NavigationStack {
            if let item = items.first(where: { $0.name == "Archived Plant" }) {
                ItemDetailView()
                    .environment(item)
            }
        }
    }
}

#Preview("Edit Item - Year Precision") {
    StallyPreviewContainer(.timeTogether) { items in
        if let item = items.first(where: { $0.name == "Home" }) {
            EditItemView()
                .environment(item)
        }
    }
}

#Preview("Library - Mixed Tracking") {
    StallyPreviewContainer(.integration) { _ in
        NavigationStack {
            LibraryView(
                addAction: { /* Preview action intentionally left empty. */ },
                restoreAction: { /* Preview action intentionally left empty. */ }
            )
        }
    }
}

#Preview("Insights - Time Together") {
    StallyPreviewContainer(.timeTogether) { _ in
        NavigationStack {
            InsightsView()
        }
    }
}

#Preview("Review - Mixed Tracking") {
    StallyPreviewContainer(.integration) { _ in
        NavigationStack {
            ReviewView()
        }
    }
}
#endif
