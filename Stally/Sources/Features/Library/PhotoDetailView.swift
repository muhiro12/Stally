import StallyLibrary
import SwiftUI

struct PhotoDetailView: View {
    @Environment(\.dismiss)
    private var dismiss
    let photo: ItemDraft.Photo
    @State private var image: CGImage?
    @State private var errorMessage: String?

    private var photoContent: some View {
        ScrollView {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(photo.caption.isEmpty ? String(localized: "Photo") : photo.caption)
            } else if let errorMessage {
                ContentUnavailableView("Photo unavailable", systemImage: "photo", description: Text(errorMessage))
            } else {
                ProgressView()
            }
            if !photo.caption.isEmpty {
                Text(photo.caption).padding()
            }
        }
    }

    var body: some View {
        NavigationStack {
            photoContent
                .navigationTitle("Photo")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") {
                            dismiss()
                        }
                    }
                }
                .task {
                    do {
                        guard let data = photo.imageData else {
                            throw RecordError.invalidPhoto
                        }
                        image = try await PhotoOperations.image(data: data)
                    } catch is CancellationError {
                        return
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
        }
    }
}
