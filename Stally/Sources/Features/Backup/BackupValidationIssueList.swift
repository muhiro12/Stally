//
//  BackupValidationIssueList.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupValidationIssueList: View {
    let issues: [BackupValidationIssue]

    var body: some View {
        MHGroupedRows {
            if issues.isEmpty {
                Text("No validation issues were found in this backup.")
                    .mhRowSupporting()
            } else {
                ForEach(issues) { issue in
                    BackupValidationIssueRow(issue: issue)
                }
            }
        }
    }
}
