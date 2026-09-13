#if DEBUG
import SwiftUI

#Preview("Item Detail - Non Mark Month") {
    StallyPreviewContainer(.timeTogether) { items in
        NavigationStack {
            if let item = items.first(where: { $0.name == "Window Plant" }) {
                ItemDetailView(item: item)
            }
        }
    }
}

#Preview("Item Detail - Archived Day") {
    StallyPreviewContainer(.timeTogether) { items in
        NavigationStack {
            if let item = items.first(where: { $0.name == "Archived Plant" }) {
                ItemDetailView(item: item)
            }
        }
    }
}

#Preview("Edit Item - Year Precision") {
    StallyPreviewContainer(.timeTogether) { items in
        if let item = items.first(where: { $0.name == "Home" }) {
            EditItemView(item: item)
        }
    }
}

#Preview("Library - Mixed Tracking") {
    StallyPreviewContainer(.integration) { items in
        NavigationStack {
            LibraryView(
                items: ItemOperations.activeItems(from: items),
                allowsSampleItems: false,
                addAction: { /* Preview action intentionally left empty. */ },
                restoreAction: { /* Preview action intentionally left empty. */ }
            )
        }
    }
}

#Preview("Insights - Time Together") {
    StallyPreviewContainer(.timeTogether) { items in
        NavigationStack {
            InsightsView(items: items)
        }
    }
}

#Preview("Review - Mixed Tracking") {
    StallyPreviewContainer(.integration) { items in
        NavigationStack {
            ReviewView(snapshot: ReviewOperations.snapshot(for: items))
        }
    }
}
#endif
