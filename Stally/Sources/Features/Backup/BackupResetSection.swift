//
//  BackupResetSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct BackupResetSection: View {
    @Environment(\.mhTheme)
    private var theme

    let deleteEverythingAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            MHSectionHeader("Reset Tools")

            MHActionGroup {
                Button("Delete Every Item", role: .destructive, action: deleteEverythingAction)
                    .buttonStyle(.mhDestructive)
            }
        }
    }
}
