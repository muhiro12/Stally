//
//  InsightsActivitySection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct InsightsActivitySection: View {
    let snapshot: InsightsSnapshot

    var body: some View {
        Section("Activity") {
            if snapshot.totalMarks == 0 {
                Text("No activity in this window yet.")
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Marks") {
                Text(snapshot.totalMarks, format: .number)
            }

            LabeledContent("Active Days") {
                Text(snapshot.activeDays, format: .number)
            }

            LabeledContent("Unique Items") {
                Text(snapshot.uniqueMarkedItems, format: .number)
            }

            LabeledContent("Unique Categories") {
                Text(snapshot.uniqueMarkedCategories, format: .number)
            }
        }
    }
}
