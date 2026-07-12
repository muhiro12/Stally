//
//  HistoryAdjustmentEntrySection.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

import MHUI
import SwiftUI

struct HistoryAdjustmentEntrySection: View {
    let adjustAction: () -> Void

    var body: some View {
        Section {
            Button(action: adjustAction) {
                Label("Adjust History", systemImage: "calendar")
            }
            .buttonStyle(.mhSecondary)
        }
    }
}
