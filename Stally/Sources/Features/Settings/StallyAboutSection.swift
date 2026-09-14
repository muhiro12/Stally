//
//  StallyAboutSection.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

import Foundation
import MHPlatform
import MHUI
import SwiftUI

struct StallyAboutSection: View {
    private static let supportURL: URL = {
        guard let url = URL(string: "https://muhiro12.github.io/Stally/") else {
            preconditionFailure("The Stally support URL must be valid.")
        }
        return url
    }()

    private static let privacyPolicyURL: URL = {
        guard let url = URL(
            string: "https://muhiro12.github.io/Stally/privacy.html"
        ) else {
            preconditionFailure("The Stally privacy policy URL must be valid.")
        }
        return url
    }()

    @Environment(MHAppRuntime.self)
    private var appRuntime

    var body: some View {
        Section {
            Link(destination: Self.supportURL) {
                Label("Support", systemImage: "questionmark.circle")
                    .mhTextStyle(.body, colorRole: .primaryText)
            }
            .mhRow()

            Link(destination: Self.privacyPolicyURL) {
                Label("Privacy Policy", systemImage: "hand.raised")
                    .mhTextStyle(.body, colorRole: .primaryText)
            }
            .mhRow()

            NavigationLink {
                appRuntime.licensesView()
                    .navigationTitle("Licenses")
            } label: {
                Label("Licenses", systemImage: "doc.text")
            }
            .mhRow()
        } header: {
            MHSectionHeader("About")
        }
    }
}
