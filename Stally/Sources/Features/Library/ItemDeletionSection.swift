//
//  ItemDeletionSection.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

import MHUI
import SwiftUI

struct ItemDeletionSection: View {
    let deleteAction: () -> Void

    var body: some View {
        MHActionGroup {
            Button(role: .destructive, action: deleteAction) {
                Label("Delete Item", systemImage: "trash")
            }
            .buttonStyle(.mhDestructive)
        }
        .mhSection(
            "Delete Item",
            supporting: "Deleting this item also removes all of its marks."
        )
    }
}
