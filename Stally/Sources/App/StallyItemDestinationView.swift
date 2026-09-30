import SwiftData
import SwiftUI

/// Resolves a stable route at the destination boundary, then supplies one live Item.
struct StallyItemDestinationView: View {
    @Environment(\.modelContext)
    private var modelContext

    let itemID: UUID

    private var resolution: Result<Item?, any Error> {
        .init {
            try ItemOperations.item(context: modelContext, uuid: itemID)
        }
    }

    var body: some View {
        switch resolution {
        case .success(.some(let item)):
            ItemDetailView()
                .environment(item)
        case .success(.none):
            ContentUnavailableView(
                "Unsupported Link",
                systemImage: "link.badge.plus",
                description: Text("This link is not supported by this version of Stally.")
            )
        case .failure(let error):
            ContentUnavailableView {
                Label("Stally", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            }
        }
    }
}
