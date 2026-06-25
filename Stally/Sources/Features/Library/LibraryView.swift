//
//  LibraryView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct LibraryView: View {
    let items: [Item]
    let addAction: () -> Void
    let settingsAction: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyLibraryView(addAction: addAction)
                } else {
                    ItemLibraryList(items: items)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: settingsAction) {
                        Label("Settings", systemImage: "gear")
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    StallyLinkShareButton(
                        link: .destination(.library),
                        title: "Share Library Link"
                    )

                    Button(action: addAction) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }
}
