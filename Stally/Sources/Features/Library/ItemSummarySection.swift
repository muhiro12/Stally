import MHUI
import StallyLibrary
import SwiftUI

struct ItemSummarySection: View {
    @Environment(\.openURL)
    private var openURL
    @Environment(\.mhTheme)
    private var theme
    let item: Item
    let chooseTags: () -> Void
    @State private var linkFailed = false

    private var tags: [Tag] {
        (item.tags ?? []).sorted { first, second in
            first.name.localizedStandardCompare(second.name) == .orderedAscending
        }
    }

    var body: some View {
        Section {
            summary
            if let value = item.representativeURL, let url = URL(string: value) {
                Button("Open Link", systemImage: "arrow.up.right.square") {
                    openURL(url) { accepted in
                        linkFailed = !accepted
                    }
                }
            }
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
            .mhForegroundStyle(.primaryText)
        }
        .alert("Could Not Open Link", isPresented: $linkFailed) {
            Button("OK", role: .cancel) {
                linkFailed = false
            }
        } message: {
            Text("The destination could not be opened on this device.")
        }
    }
    private var summary: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            if item.isFavorite || item.isArchived {
                HStack {
                    if item.isFavorite {
                        Label("Favorite", systemImage: "star.fill").mhBadge(style: .neutral)
                    }
                    if item.isArchived {
                        Label("Archived", systemImage: "archivebox").mhBadge(style: .neutral)
                    }
                }
                .labelStyle(.titleAndIcon)
            }
            if !item.note.isEmpty {
                Text(item.note).mhTextStyle(.body).textSelection(.enabled)
            } else {
                Text("A place for the things you want to remember.").mhRowSupporting()
            }
        }
    }
}
