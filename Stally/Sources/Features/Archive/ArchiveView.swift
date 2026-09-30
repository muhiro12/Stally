//
//  ArchiveView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftData
import SwiftUI

struct ArchiveView: View {
    @Query(filter: #Predicate<Item> { $0.archivedAt != nil }, sort: \Item.archivedAt, order: .reverse)
    private var items: [Item]

    var body: some View {
        Group {
            if items.isEmpty {
                EmptyArchiveView()
            } else {
                ItemLibraryList(items: items, kind: .archive)
            }
        }
        .navigationTitle("Archive")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StallyLinkShareButton(
                    link: .destination(.archive),
                    title: "Share Archive Link"
                )
            }
        }
    }
}
