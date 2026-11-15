import StallyLibrary
import SwiftUI

struct PhotoPreview: View {
    let data: Data?

    var body: some View {
        if let data, let image = PhotoOperations.preview(data: data) {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "photo")
                .accessibilityLabel("Photo unavailable")
        }
    }
}
