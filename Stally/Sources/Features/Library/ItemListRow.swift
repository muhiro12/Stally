import MHUI
import StallyLibrary
import SwiftUI

struct ItemListRow: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(Item.self)
    private var item
    @Environment(\.markToday)
    private var today
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.inline))
            : AnyLayout(HStackLayout(spacing: theme.spacing.control))
        layout {
            if let photo = ItemOperations.orderedPhotos(for: item).first {
                PhotoPreview(data: photo.thumbnailData ?? photo.imageData, contentMode: .fill)
                    .frame(width: LibraryLayout.listPhotoSize, height: LibraryLayout.listPhotoSize)
                    .clipShape(.rect(cornerRadius: theme.cornerRadius.control))
                    .accessibilityHidden(true)
            }
            summary
        }
        .accessibilityElement(children: .combine)
    }

    private var summary: some View {
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
            if let note = item.note {
                Text(note).mhRowSupporting().lineLimit(LibraryLayout.previewLines)
            }
            HStack(spacing: theme.spacing.control) {
                Label("\((item.marks ?? []).count)", systemImage: "checkmark.circle")
                    .accessibilityLabel("\((item.marks ?? []).count) Marks")
                if let count = MarkOperations.countsByDay(for: item, in: today...today)[today] {
                    Text("Today: \(count)")
                }
                if item.isArchived {
                    Label("Archived", systemImage: "archivebox")
                } else if !item.isMarkRecordingEnabled {
                    Label("Recording Paused", systemImage: "pause.circle")
                }
            }
            .mhTextStyle(.caption, colorRole: .secondaryText)
        }
    }
}
