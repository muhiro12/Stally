//
//  ItemFormFields.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct ItemFormFields: View {
    @Binding var name: String
    @Binding var category: ItemCategory
    @Binding var note: String
    @Binding var photoData: Data?
    @Binding var isLoadingPhoto: Bool

    let noteLineLimit: Int

    var body: some View {
        Section {
            TextField("Name", text: $name)

            Picker("Category", selection: $category) {
                ForEach(ItemCategory.allCases) { category in
                    Text(category.title)
                        .tag(category)
                }
            }

            TextField("Note", text: $note, axis: .vertical)
                .lineLimit(noteLineLimit, reservesSpace: true)
        }

        ItemPhotoFormSection(
            photoData: $photoData,
            isLoadingPhoto: $isLoadingPhoto
        )
    }
}
