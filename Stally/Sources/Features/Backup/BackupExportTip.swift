//
//  BackupExportTip.swift
//  Stally
//
//  Created by Codex on 2026/07/16.
//

import SwiftUI
import TipKit

struct BackupExportTip: Tip {
    var title: Text {
        Text("Keep a portable snapshot")
    }

    var message: Text? {
        Text("Backup files are for archiving and transfer, not ongoing sync between devices.")
    }

    var options: [Option] {
        MaxDisplayCount(1)
    }
}
