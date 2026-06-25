//
//  BackupResetSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct BackupResetSection: View {
    let deleteEverythingAction: () -> Void

    var body: some View {
        Section("Reset Tools") {
            Text("Delete Everything intentionally creates an empty library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Delete Every Item", role: .destructive, action: deleteEverythingAction)
        }
    }
}
