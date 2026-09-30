//
//  EmptyLibraryView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct EmptyLibraryView: View {
    let addAction: () -> Void
    let sampleAction: (() -> Void)?
    let restoreAction: () -> Void

    var body: some View {
        List {
            // Preserve the native list canvas behind the empty state.
        }
        .stallyListChrome(.content)
        .overlay {
            ContentUnavailableView {
                Label("Start Your Library", systemImage: "tray")
            } description: {
                Text("Keep the things and places that matter to you.")
            } actions: {
                Button("Add Your First Item", action: addAction)
                    .buttonStyle(.mhPrimary)

                if let sampleAction {
                    Button("Try Sample Items", action: sampleAction)
                        .buttonStyle(.mhSecondary)
                }

                Button(action: restoreAction) {
                    Text("Import Data")
                        .mhForegroundStyle(.primaryText)
                }
                .buttonStyle(.mhQuiet)
            }
            .mhEmptyStateLayout()
        }
    }
}
