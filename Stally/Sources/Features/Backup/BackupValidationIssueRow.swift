//
//  BackupValidationIssueRow.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupValidationIssueRow: View {
    private enum Layout {
        static let spacing: CGFloat = 4
    }

    let issue: BackupValidationIssue

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            Label {
                Text(issue.title)
                    .mhRowTitle()
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
            .mhTextStyle(.bodyStrong, colorRole: .warning)

            if let value = issue.value, !value.isEmpty {
                Text(value)
                    .mhTextStyle(.caption, colorRole: .secondaryText)
            }
        }
    }
}
