import MHUI
import PhotosUI
import StallyLibrary
import SwiftUI

struct ItemDraftPhotosSection: View {
    @Binding var draft: ItemDraft
    @Binding var loading: Bool
    @Binding var errorMessage: String?
    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        Section {
            ForEach($draft.photos) { $photo in
                VStack(alignment: .leading) {
                    PhotoPreview(data: photo.thumbnailData ?? photo.imageData)
                        .frame(maxHeight: LibraryLayout.editorPhotoHeight)
                    TextField("Caption", text: $photo.caption, axis: .vertical)
                    photoActions(photo.id)
                }
            }
            PhotosPicker(
                selection: $selection,
                selectionBehavior: .ordered,
                matching: .images,
                preferredItemEncoding: .current
            ) {
                Label("Add Photos", systemImage: "photo.badge.plus")
            }
            .disabled(loading)
            if loading {
                ProgressView("Preparing Photos")
            }
        } header: {
            MHSectionHeader("Photos")
        }
        .task(id: selection) {
            await loadSelection()
        }
    }

    private func photoActions(_ id: UUID) -> some View {
        HStack {
            Button {
                move(id, offset: -1)
            } label: {
                actionLabel("Move Photo Up", systemImage: "arrow.up")
            }
            .disabled(draft.photos.first?.id == id)
            Button {
                move(id, offset: 1)
            } label: {
                actionLabel("Move Photo Down", systemImage: "arrow.down")
            }
            .disabled(draft.photos.last?.id == id)
            Spacer()
            Button(role: .destructive) {
                draft.photos.removeAll { $0.id == id }
            } label: {
                actionLabel("Remove Photo", systemImage: "trash")
            }
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
    }

    private func actionLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .frame(minWidth: LibraryLayout.minimumControlSize, minHeight: LibraryLayout.minimumControlSize)
            .contentShape(.rect)
    }

    private func move(_ id: UUID, offset: Int) {
        guard let index = draft.photos.firstIndex(where: { $0.id == id }),
              draft.photos.indices.contains(index + offset)
        else {
            return
        }
        draft.photos.swapAt(index, index + offset)
    }

    private func loadSelection() async {
        guard !selection.isEmpty else {
            return
        }
        loading = true
        defer {
            loading = false
        }
        do {
            var prepared: [ItemDraft.Photo] = []
            for selected in selection {
                try Task.checkCancellation()
                guard let photo = try await selected.loadTransferable(type: ImportedPhoto.self) else {
                    throw RecordError.invalidPhoto
                }
                prepared.append(.init(prepared: photo.prepared))
            }
            try Task.checkCancellation()
            draft.photos.append(contentsOf: prepared)
            selection = []
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            selection = []
        }
    }
}
