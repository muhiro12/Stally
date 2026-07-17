//
//  SettingsICloudSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import MHUI
import SwiftUI

struct SettingsICloudSection: View {
    @Binding var isICloudOn: Bool

    var body: some View {
        Section {
            Toggle("iCloud Sync", isOn: $isICloudOn)
                .mhRow()
        } header: {
            MHSectionHeader("iCloud")
        } footer: {
            MHSectionFooter("iCloud sync changes take effect the next time Stally starts.")
        }
    }
}
