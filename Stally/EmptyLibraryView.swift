//
//  EmptyLibraryView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct EmptyLibraryView: View {
    let addAction: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Start Your Library", systemImage: "tray")
        } description: {
            Text("Start with a few pieces you actually reach for.")
        } actions: {
            Button("Add Your First Item", action: addAction)
                .buttonStyle(.borderedProminent)
        }
    }
}
