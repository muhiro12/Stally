//
//  EditItemView.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

import SwiftUI

struct EditItemView: View {
    @Environment(Item.self)
    private var item

    var body: some View {
        EditItemForm(
            input: .init(name: item.name, category: item.category, note: item.note, photoData: item.photoData),
            tracking: .init(item: item)
        )
        .id(item.uuid)
    }
}
