//
//  SettingsReviewSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import SwiftUI

struct SettingsReviewSection: View {
    private enum DayRange {
        static let minimum = 1
        static let maximumFirstMark = 365
        static let maximumDormant = 730
    }

    @Binding var needsFirstMarkAfterDays: Int
    @Binding var dormantAfterDays: Int
    @Binding var showsCompletedSections: Bool

    var body: some View {
        Section {
            Stepper(
                value: $needsFirstMarkAfterDays,
                in: DayRange.minimum ... DayRange.maximumFirstMark
            ) {
                LabeledContent("First mark (days)") {
                    Text(needsFirstMarkAfterDays, format: .number)
                }
            }

            Stepper(
                value: $dormantAfterDays,
                in: DayRange.minimum ... DayRange.maximumDormant
            ) {
                LabeledContent("Dormant (days)") {
                    Text(dormantAfterDays, format: .number)
                }
            }

            Toggle("Show completed sections", isOn: $showsCompletedSections)
        } header: {
            StallySectionHeader("Review")
        }
    }
}
