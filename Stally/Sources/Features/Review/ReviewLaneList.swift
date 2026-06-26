//
//  ReviewLaneList.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct ReviewLaneList: View {
    let snapshot: ReviewSnapshot

    var body: some View {
        List {
            ForEach(ReviewLane.allCases) { lane in
                ReviewLaneSection(
                    lane: lane,
                    items: snapshot.items(in: lane)
                )
            }
        }
        .stallyListChrome()
    }
}
