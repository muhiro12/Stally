//
//  ArchiveView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct ArchiveView: View {
    let items: [Item]

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyArchiveView()
                } else {
                    ItemLibraryList(items: items)
                }
            }
            .navigationTitle("Archive")
        }
    }
}
