//
//  HistoryAdjustmentDateSection.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

import MHUI
import SwiftUI

struct HistoryAdjustmentDateSection: View {
    @Binding var selectedDate: Date

    let latestDate: Date

    var body: some View {
        Section {
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: ...latestDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .mhRow()
        }
    }
}
