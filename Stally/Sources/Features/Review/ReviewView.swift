//
//  ReviewView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import SwiftData
import SwiftUI

struct ReviewView: View {
    @Query(sort: \Item.createdAt, order: .reverse)
    private var items: [Item]
    @Environment(\.timeZone)
    private var timeZone
    @AppStorage(\.needsFirstMarkAfterDays)
    private var needsFirstMarkAfterDays
    @AppStorage(\.dormantAfterDays)
    private var dormantAfterDays
    @AppStorage(\.showsCompletedReviewSections)
    private var showsCompletedReviewSections

    var body: some View {
        let snapshot = ReviewOperations.snapshot(
            for: items,
            settings: .init(
                needsFirstMarkAfterDays: needsFirstMarkAfterDays,
                dormantAfterDays: dormantAfterDays
            ),
            timeZone: timeZone,
            now: .now
        )
        Group {
            if snapshot.isEmpty {
                EmptyReviewView()
            } else {
                ReviewLaneList(
                    snapshot: snapshot,
                    showsCompletedSections: showsCompletedReviewSections
                )
            }
        }
        .navigationTitle("Review")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StallyLinkShareButton(
                    link: .destination(.review),
                    title: "Share Review Link"
                )
            }
        }
    }
}
