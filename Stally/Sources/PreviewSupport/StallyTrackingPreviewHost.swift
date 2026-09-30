#if DEBUG
import SwiftUI

/// Hosts the real screens with the launch configuration's in-memory preview data.
struct StallyTrackingPreviewHost: View {
    let screen: StallyTrackingPreviewScreen
    let items: [Item]

    var body: some View {
        if let item = items.first(where: { $0.uuid == screen.itemID }) {
            if screen.showsEditor {
                EditItemView()
                    .environment(item)
            } else {
                NavigationStack {
                    ItemDetailView()
                        .environment(item)
                }
            }
        }
    }
}
#endif
