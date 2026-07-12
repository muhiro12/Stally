//
//  InsightsView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct InsightsView: View {
    @Environment(\.timeZone)
    private var timeZone

    let items: [Item]

    @State private var selectedRange: InsightsRange = .thirtyDays
    @State private var includesArchivedItems = false

    private var options: InsightsOptions {
        .init(
            range: selectedRange,
            includesArchivedItems: includesArchivedItems
        )
    }

    var body: some View {
        let now = Date()
        let snapshot = InsightsOperations.snapshot(
            for: items,
            options: options,
            timeZone: timeZone,
            now: now
        )

        NavigationStack {
            InsightsList(
                snapshot: snapshot,
                selectedRange: $selectedRange,
                includesArchivedItems: $includesArchivedItems
            )
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StallyLinkShareButton(
                        link: .destination(.insights),
                        title: "Share Insights Link"
                    )
                }
            }
        }
    }
}
