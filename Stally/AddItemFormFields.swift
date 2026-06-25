//
//  AddItemFormFields.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct AddItemFormFields: View {
    @Binding var name: String
    @Binding var category: ItemCategory
    @Binding var note: String

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
        } footer: {
            Text("A short note can make this item's history easier to read later.")
        }
    }
}
