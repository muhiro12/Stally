import StallyLibrary
import SwiftData
import SwiftUI

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyBackupCenterView(
            items: items
        )
    }
}
