//
//  BackupValidationIssueList.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct BackupValidationIssueList: View {
    let issues: [BackupValidationIssue]

    var body: some View {
        if issues.isEmpty {
            Text("No validation issues were found in this backup.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(issues) { issue in
                BackupValidationIssueRow(issue: issue)
            }
        }
    }
}
