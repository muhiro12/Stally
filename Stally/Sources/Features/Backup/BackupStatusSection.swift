//
//  BackupStatusSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupStatusSection: View {
    let message: String

    var body: some View {
        MHGroupedRows {
            Text(message)
                .mhRowSupporting()
        }
        .mhSection("Last Result")
    }
}
