//
//  ReviewLaneSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct ReviewLaneSection: View {
    let lane: ReviewLane
    let items: [Item]

    var body: some View {
        Section {
            Text(lane.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if items.isEmpty {
                Text(lane.emptyMessage)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ItemRow(item: item)
                    }
                }
            }
        } header: {
            Text(lane.title)
        }
    }
}
