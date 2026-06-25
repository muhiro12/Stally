//
//  BackupValidationIssueRow.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

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
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
            .foregroundStyle(.orange)

            if let value = issue.value, !value.isEmpty {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
