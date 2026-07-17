//
//  SettingsSubscriptionSection.swift
//  Stally
//
//  Created by Codex on 2026/06/28.
//

import SwiftUI

struct SettingsSubscriptionSection: View {
    let isSubscribeOn: Bool

    var body: some View {
        Section {
            if isSubscribeOn {
                Label("Ads Removed", systemImage: "checkmark.seal")
            } else {
                Label("Premium", systemImage: "creditcard")
            }
        } header: {
            StallySectionHeader("Subscription")
        }
    }
}
