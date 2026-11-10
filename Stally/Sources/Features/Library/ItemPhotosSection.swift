import MHUI
import StallyLibrary
import SwiftUI

struct ItemPhotosSection: View {
    let item: Item
    let onSelect: (ItemDraft.Photo) -> Void

    private var photos: [ItemDraft.Photo] {
        ItemOperations.draft(for: item).photos
    }

    var body: some View {
        if !photos.isEmpty {
            Section {
                ForEach(photos) { photo in
                    Button {
                        onSelect(photo)
                    } label: {
                        VStack(alignment: .leading) {
                            PhotoPreview(data: photo.thumbnailData ?? photo.imageData)
                                .frame(maxHeight: LibraryLayout.detailPhotoHeight)
                            if !photo.caption.isEmpty {
                                Text(photo.caption).mhTextStyle(.body)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(photo.caption.isEmpty ? String(localized: "View Photo") : photo.caption)
                }
            } header: {
                MHSectionHeader("Photos")
            }
        }
    }
}
