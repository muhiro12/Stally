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
    private static let privacyPolicyURL: URL = {
        guard let url = URL(
            string: "https://muhiro12.github.io/Stally/privacy.html"
        ) else {
            preconditionFailure("The Stally privacy policy URL must be valid.")
        }
        return url
    }()

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

                Section("Privacy") {
                    Link(destination: Self.privacyPolicyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    .mhRow()
                }
            }
            .stallyListChrome()
            .navigationTitle("Settings")
        }
    }
}
