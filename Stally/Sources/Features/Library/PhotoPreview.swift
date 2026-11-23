import StallyLibrary
import SwiftUI

struct PhotoPreview: View {
    let data: Data?
    var contentMode: ContentMode = .fit

    var body: some View {
        if let data, let image = PhotoOperations.preview(data: data) {
            Image(decorative: image, scale: 1)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            Image(systemName: "photo")
                .accessibilityLabel("Photo unavailable")
        }
    }
}
