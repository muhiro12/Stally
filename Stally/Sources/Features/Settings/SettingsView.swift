//
//  SettingsView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Settings") {
                    Text("Quiet app details and shareable routes live here while the rebuild continues.")
                        .foregroundStyle(.secondary)
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
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
