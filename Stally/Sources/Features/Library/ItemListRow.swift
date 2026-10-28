import StallyLibrary
import SwiftUI

struct ItemListRow: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: LibraryLayout.rowSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name).font(.headline).lineLimit(LibraryLayout.previewLines)
                Spacer(minLength: LibraryLayout.iconSpacing)
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Favorite")
                }
            }
            if !item.note.isEmpty {
                Text(item.note).font(.subheadline).foregroundStyle(.secondary).lineLimit(LibraryLayout.previewLines)
            }
            HStack(spacing: LibraryLayout.sectionSpacing) {
                Label("\((item.marks ?? []).count)", systemImage: "checkmark.circle")
                    .accessibilityLabel("\((item.marks ?? []).count) Marks")
                if item.isArchived {
                    Label("Archived", systemImage: "archivebox")
                } else if !item.isMarkRecordingEnabled {
                    Label("Recording Paused", systemImage: "pause.circle")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, LibraryLayout.rowSpacing)
        .accessibilityElement(children: .combine)
    }
}
