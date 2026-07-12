//
//  StallyEditItemPreview.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

#if DEBUG
import SwiftUI

struct StallyEditItemPreview: View {
    let items: [Item]

    private var selectedItem: Item? {
        ItemOperations.activeItems(from: items).first
    }

    var body: some View {
        if let selectedItem {
            EditItemView(item: selectedItem)
        } else {
            ContentUnavailableView {
                Label("No Preview Item", systemImage: "tray")
            } description: {
                Text("Preview data did not create an item.")
            }
        }
    }
}
#endif
