//
//  SettingsICloudSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import MHUI
import SwiftUI

struct SettingsICloudSection: View {
    private let footerSpacing: CGFloat = 4

    @Binding var isICloudOn: Bool

    let persistenceStatus: StallyPlatformEnvironment.PersistenceStatus

    private var statusMessage: LocalizedStringResource {
        switch persistenceStatus {
        case .local:
            "iCloud sync is off for this launch."
        case .cloudKit:
            "iCloud sync is on for this launch."
        case .cloudKitUnavailable:
            "iCloud sync could not start. Stally is using local storage for this launch."
        }
    }

    var body: some View {
        Section {
            Toggle("iCloud Sync", isOn: $isICloudOn)
                .mhRow()
        } header: {
            MHSectionHeader("iCloud")
        } footer: {
            VStack(alignment: .leading, spacing: footerSpacing) {
                Text(statusMessage)
                Text("iCloud sync changes take effect the next time Stally starts.")
            }
        }
    }
}
