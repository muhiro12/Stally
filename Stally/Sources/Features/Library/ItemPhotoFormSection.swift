//
//  ItemPhotoFormSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import PhotosUI
import SwiftUI

struct ItemPhotoFormSection: View {
    private enum Layout {
        static let thumbnailMaximumHeight: CGFloat = 220
    }

    @Binding var photoData: Data?
    @Binding var isLoadingPhoto: Bool

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoErrorMessage: String?

    var body: some View {
        let hasPhoto = photoData != nil

        Section {
            if let photoData {
                ItemPhotoImage(photoData: photoData)
                    .frame(maxHeight: Layout.thumbnailMaximumHeight)
            }

            if isLoadingPhoto || photoErrorMessage != nil {
                ItemPhotoFeedback(
                    isLoading: isLoadingPhoto,
                    errorMessage: photoErrorMessage
                )
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                if hasPhoto {
                    Label("Change Photo", systemImage: "photo.badge.arrow.down")
                } else {
                    Label("Choose Photo", systemImage: "photo.badge.plus")
                }
            }

            if photoData != nil {
                Button(role: .destructive, action: removePhoto) {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        } header: {
            StallySectionHeader("Photo")
        }
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else {
                return
            }

            await loadPhoto(selectedPhotoItem)
        }
    }
}

private extension ItemPhotoFormSection {
    func loadPhoto(_ photoItem: PhotosPickerItem) async {
        isLoadingPhoto = true
        photoErrorMessage = nil

        do {
            let preparedPhotoData = try await ItemPhotoSelectionLoader.load(photoItem)
            try Task.checkCancellation()

            guard selectedPhotoItem == photoItem else {
                return
            }

            photoData = preparedPhotoData
            selectedPhotoItem = nil
            isLoadingPhoto = false
        } catch is CancellationError {
            guard selectedPhotoItem == photoItem else {
                return
            }

            isLoadingPhoto = false
        } catch {
            guard selectedPhotoItem == photoItem else {
                return
            }

            photoErrorMessage = error.localizedDescription
            selectedPhotoItem = nil
            isLoadingPhoto = false
        }
    }

    func removePhoto() {
        selectedPhotoItem = nil
        photoData = nil
        photoErrorMessage = nil
        isLoadingPhoto = false
    }
}
