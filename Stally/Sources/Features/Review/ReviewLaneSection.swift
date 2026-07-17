//
//  ReviewLaneSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct ReviewLaneSection: View {
    let lane: ReviewLane
    let items: [Item]
    let itemAction: (Item) -> Void

    var body: some View {
        Section {
            if items.isEmpty {
                Text(lane.emptyMessage)
                    .mhRowSupporting()
            } else {
                ForEach(items) { item in
                    NavigationLink(value: StallyNavigationView.DetailRoute.item(item.uuid)) {
                        ItemRow(item: item)
                    }
                    .tag(item.uuid)
                    .swipeActions {
                        Button(
                            action: { itemAction(item) },
                            label: {
                                switch lane {
                                case .dormant, .needsFirstMark:
                                    Label("Archive Item", systemImage: "archivebox")
                                case .recoveryCandidates:
                                    Label("Move Back to Library", systemImage: "tray.and.arrow.up")
                                }
                            }
                        )
                    }
                }
            }
        } header: {
            StallySectionHeader(title: Text(lane.title))
        }
    }
}
