//
//  ReviewLaneSection.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct ReviewLaneSection: View {
    private enum Layout {
        static let headerSpacing: CGFloat = 4
    }

    let lane: ReviewLane
    let items: [Item]

    var body: some View {
        Section {
            if items.isEmpty {
                Text(lane.emptyMessage)
                    .mhRowSupporting()
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
            VStack(alignment: .leading, spacing: Layout.headerSpacing) {
                Text(lane.title)
                    .mhSectionHeaderTitle()

                Text(lane.summary)
                    .mhSectionHeaderSupporting()
            }
            .mhSectionHeader()
        }
    }
}
