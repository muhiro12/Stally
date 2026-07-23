//
//  InsightsView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import SwiftUI

struct InsightsView: View {
    @Environment(\.timeZone)
    private var timeZone

    let items: [Item]

    @AppStorage(\.defaultInsightsRange, default: .thirtyDays)
    private var selectedRange: InsightsRange
    @AppStorage(\.includesArchivedItemsInInsights)
    private var includesArchivedItems

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

        InsightsList(
            snapshot: snapshot,
            selectedRange: $selectedRange,
            includesArchivedItems: $includesArchivedItems
        )
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
