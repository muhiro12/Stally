import MHUI
import StallyLibrary
import SwiftUI

struct ItemListRow: View {
    @Environment(\.mhTheme)
    private var theme
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.inline) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name).mhRowTitle().lineLimit(LibraryLayout.previewLines)
                Spacer(minLength: theme.spacing.inline)
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .mhForegroundStyle(.secondaryText)
                        .accessibilityLabel("Favorite")
                }
            }
            if !item.note.isEmpty {
                Text(item.note).mhRowSupporting().lineLimit(LibraryLayout.previewLines)
            }
            HStack(spacing: theme.spacing.control) {
                Label("\((item.marks ?? []).count)", systemImage: "checkmark.circle")
                    .accessibilityLabel("\((item.marks ?? []).count) Marks")
                if item.isArchived {
                    Label("Archived", systemImage: "archivebox")
                } else if !item.isMarkRecordingEnabled {
                    Label("Recording Paused", systemImage: "pause.circle")
                }
            }
            .mhTextStyle(.caption, colorRole: .secondaryText)
        }
        .accessibilityElement(children: .combine)
    }
}
