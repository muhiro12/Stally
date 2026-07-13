//
//  ItemDetailPhotoSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import SwiftUI

struct ItemDetailPhotoSection: View {
    private enum Layout {
        static let maximumHeight: CGFloat = 360
        static let verticalPadding: CGFloat = 4
    }

    let photoData: Data

    var body: some View {
        Section {
            ItemPhotoImage(photoData: photoData)
                .frame(maxHeight: Layout.maximumHeight)
                .padding(.vertical, Layout.verticalPadding)
        }
    }
}
