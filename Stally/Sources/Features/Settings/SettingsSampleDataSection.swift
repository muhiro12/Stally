//
//  SettingsSampleDataSection.swift
//  Stally
//
//  Created by Codex on 2026/07/17.
//

import MHUI
import SwiftUI

struct SettingsSampleDataSection: View {
    let itemCount: Int
    let markCount: Int
    let removeAction: () -> Void

    var body: some View {
        Section {
            LabeledContent("Sample Items") {
                Text(itemCount, format: .number)
            }
            .mhRow()

            LabeledContent("Sample Marks") {
                Text(markCount, format: .number)
            }
            .mhRow()

            Button(
                "Remove Sample Items",
                role: .destructive,
                action: removeAction
            )
            .buttonStyle(.mhDestructive)
        } header: {
            MHSectionHeader("Sample Data")
        } footer: {
            MHSectionFooter(
                // swiftlint:disable:next line_length
                "Sample items use the same Library, history, Review, Insights, Archive, backup, and sync features as your own items."
            )
        }
    }
}
