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
    let isMarkedToday: Bool

    var body: some View {
        MHSummary(
            title: statusTitle,
            metadata: Text(item.category.title),
            supporting: item.note.isEmpty ? nil : Text(item.note)
        )
    }

    private var statusTitle: Text {
        if item.isArchived {
            return Text("Archived")
        }

        if isMarkedToday {
            return Text("Marked Today")
        }

        return Text("Not marked")
    }
}
