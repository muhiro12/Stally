//
//  ItemDetailSummary.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct ItemDetailSummary: View {
    let item: Item

    var body: some View {
        Section {
            MHSummary(
                title: Text(item.name),
                metadata: Text(item.category.title),
                supporting: item.note.isEmpty ? nil : Text(item.note)
            )
            .mhRow()
        }
    }
}
