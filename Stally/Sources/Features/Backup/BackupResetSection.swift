//
//  BackupResetSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupResetSection: View {
    let deleteEverythingAction: () -> Void

    var body: some View {
        MHActionGroup {
            Button("Delete Every Item", role: .destructive, action: deleteEverythingAction)
                .buttonStyle(.mhDestructive)
        }
        .mhSection("Reset Tools")
    }
}
