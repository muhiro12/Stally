import SwiftData
import SwiftUI

/// Resolves a stable route at the destination boundary, then supplies one live Item.
struct StallyItemDestinationView: View {
    private enum Presentation {
        case detail
        case edit
    }

    @Environment(\.modelContext)
    private var modelContext

    let itemID: UUID
    private let presentation: Presentation

    private var resolution: Result<Item?, any Error> {
        .init {
            try ItemOperations.item(context: modelContext, uuid: itemID)
        }
    }

    var body: some View {
        switch resolution {
        case .success(.some(let item)):
            Group {
                switch presentation {
                case .detail:
                    ItemDetailView()
                case .edit:
                    EditItemView()
                }
            }
            .environment(item)
        case .success(.none):
            if presentation == .edit {
                ContentUnavailableView("Item Unavailable", systemImage: "tray")
            } else {
                ContentUnavailableView(
                    "Unsupported Link",
                    systemImage: "link.badge.plus",
                    description: Text("This link is not supported by this version of Stally.")
                )
            }
        case .failure(let error):
            ContentUnavailableView {
                Label("Stally", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            }
        }
    }

    init(itemID: UUID) {
        self.itemID = itemID
        presentation = .detail
    }

    init(editingItemID: UUID) {
        itemID = editingItemID
        presentation = .edit
    }
}
