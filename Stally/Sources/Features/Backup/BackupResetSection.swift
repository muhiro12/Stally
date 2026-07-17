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
        Section {
            Button("Delete Every Item", role: .destructive, action: deleteEverythingAction)
                .buttonStyle(.mhDestructive)
        } header: {
            MHSectionHeader("Reset Tools")
        }
    }
}
