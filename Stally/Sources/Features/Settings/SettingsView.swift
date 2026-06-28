//
//  SettingsView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import MHUI
import SwiftUI

struct SettingsView: View {
    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(\.isICloudOn)
    private var isICloudOn

    var body: some View {
        NavigationStack {
            List {
                SettingsSubscriptionSection(
                    isSubscribeOn: isSubscribeOn,
                    isICloudOn: $isICloudOn
                )

                StallyStoreSection()

                Section("Settings") {
                    Text("Premium status and shareable routes live here during the rebuild.")
                        .mhRowSupporting()
                }

                Section("Shareable Links") {
                    ForEach(StallyLinkDestination.allCases) { destination in
                        ShareLink(item: StallyLinkOperations.url(for: .destination(destination))) {
                            Label {
                                Text(destination.title)
                            } icon: {
                                Image(systemName: destination.systemImageName)
                            }
                        }
                        .mhRow()
                    }
                }
            }
            .stallyListChrome()
            .navigationTitle("Settings")
        }
    }
}
