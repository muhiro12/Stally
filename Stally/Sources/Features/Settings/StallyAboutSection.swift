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
            Link(destination: Self.privacyPolicyURL) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            NavigationLink {
                appRuntime.licensesView()
                    .navigationTitle("Licenses")
            } label: {
                Label("Licenses", systemImage: "doc.text")
            }
        } header: {
            StallySectionHeader("About")
        }
    }
}
