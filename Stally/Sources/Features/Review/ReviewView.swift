//
//  ReviewView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import SwiftUI

struct ReviewView: View {
    @AppStorage(\.showsCompletedReviewSections)
    private var showsCompletedReviewSections

    let snapshot: ReviewSnapshot

    var body: some View {
        NavigationStack {
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
}
