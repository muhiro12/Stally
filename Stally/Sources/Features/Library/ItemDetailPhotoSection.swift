//
//  ItemDetailPhotoSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import MHUI
import SwiftUI

struct ItemDetailPhotoSection: View {
    private enum Layout {
        static let maximumHeight: CGFloat = 360
    }

    let photoData: Data

    var body: some View {
        ItemPhotoImage(photoData: photoData)
            .frame(maxHeight: Layout.maximumHeight)
            .mhSection("Photo")
    }
}
