import StallyLibrary
import SwiftUI

struct ItemSummarySection: View {
    let item: Item
    let chooseTags: () -> Void

    private var tags: [Tag] {
        (item.tags ?? []).sorted { first, second in
            first.name.localizedStandardCompare(second.name) == .orderedAscending
        }
    }

    var body: some View {
        Section {
            summary
            Button(action: chooseTags) {
                LabeledContent {
                    if tags.isEmpty {
                        Text("Add Tags")
                    } else {
                        Text(tags.map(\.name).formatted(.list(type: .and)))
                    }
                } label: {
                    Label("Tags", systemImage: "tag")
                }
            }
            .foregroundStyle(.primary)
        }
    }
    private var summary: some View {
        VStack(alignment: .leading, spacing: LibraryLayout.sectionSpacing) {
            if item.isFavorite || item.isArchived {
                HStack {
                    if item.isFavorite {
                        Label("Favorite", systemImage: "star.fill").foregroundStyle(.orange)
                    }
                    if item.isArchived {
                        Label("Archived", systemImage: "archivebox").foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
            if !item.note.isEmpty {
                Text(item.note).textSelection(.enabled)
            } else {
                Text("A place for the things you want to remember.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, LibraryLayout.iconSpacing)
    }
}
