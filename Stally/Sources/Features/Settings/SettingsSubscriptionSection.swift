//
//  SettingsSubscriptionSection.swift
//  Stally
//
//  Created by Codex on 2026/06/28.
//

import MHUI
import SwiftUI

struct SettingsSubscriptionSection: View {
    let isSubscribeOn: Bool
    @Binding var isICloudOn: Bool

    var body: some View {
        Section {
            if isSubscribeOn {
                Label("Ads Removed", systemImage: "checkmark.seal")
                    .mhRow()

                Toggle(isOn: $isICloudOn) {
                    Text("iCloud Sync")
                }
            } else {
                Label("Premium", systemImage: "creditcard")
                    .mhRow()

                Text("Subscribe to remove ads and unlock iCloud sync.")
                    .mhRowSupporting()
            }
        } header: {
            Text("Subscription")
        } footer: {
            if isSubscribeOn {
                Text("iCloud sync changes take effect the next time Stally starts.")
            }
        }
    }
}
