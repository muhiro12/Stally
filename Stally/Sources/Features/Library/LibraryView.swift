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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addAction) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }
}
