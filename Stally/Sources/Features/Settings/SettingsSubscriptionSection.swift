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

    var body: some View {
        Section {
            if isSubscribeOn {
                Label("Ads Removed", systemImage: "checkmark.seal")
                    .mhRow()
            } else {
                Label("Premium", systemImage: "creditcard")
                    .mhRow()

                Text("Subscribe to remove ads.")
                    .mhRowSupporting()
            }
        } header: {
            Text("Subscription")
        }
    }
}
