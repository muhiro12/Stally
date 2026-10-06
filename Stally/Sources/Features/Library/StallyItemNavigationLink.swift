import AppIntents
import SwiftUI

/// Domain identity disambiguates equal names across collection placement.
struct StallyItemNavigationLink: View {
    @Environment(Item.self)
    private var item

    var body: some View {
        NavigationLink(value: StallyNavigationView.DetailRoute.item(item.uuid)) {
            ItemRow()
        }
        .draggable(StallyLinkOperations.url(for: .item(item.uuid))) {
            Label("Share Item Link", systemImage: "link")
                .padding()
        }
        .modifier(ItemActionsModifier(presentation: .contextMenu))
        .appEntityIdentifier(EntityIdentifier(for: StallyItemEntity.self, identifier: item.uuid.uuidString))
    }
}
