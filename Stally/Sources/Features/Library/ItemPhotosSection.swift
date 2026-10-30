import MHUI
import StallyLibrary
import SwiftUI

struct ItemPhotosSection: View {
    let item: Item
    @State private var selected: ItemDraft.Photo?

    private var photos: [ItemDraft.Photo] {
        ItemOperations.draft(for: item).photos
    }

    var body: some View {
        if !photos.isEmpty {
            Section {
                ForEach(photos) { photo in
                    Button {
                        selected = photo
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
            .sheet(item: $selected) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }
}
