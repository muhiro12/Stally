//
//  ItemPhotoImage.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import SwiftUI
import UIKit

struct ItemPhotoImage: View {
    private enum Layout {
        static let cornerRadius: CGFloat = 16
    }

    let photoData: Data

    var body: some View {
        if let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: Layout.cornerRadius))
                .accessibilityLabel("Item Photo")
        }
    }
}
