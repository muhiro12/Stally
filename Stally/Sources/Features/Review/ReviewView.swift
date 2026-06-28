//
//  ReviewView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct ReviewView: View {
    let snapshot: ReviewSnapshot

    var body: some View {
        NavigationStack {
            Group {
                if snapshot.isEmpty {
                    EmptyReviewView()
                } else {
                    ReviewLaneList(snapshot: snapshot)
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
