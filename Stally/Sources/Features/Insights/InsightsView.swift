//
//  InsightsView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import SwiftData
import SwiftUI

struct InsightsView: View {
    @Environment(\.timeZone)
    private var timeZone

    @Query(sort: \Item.createdAt, order: .reverse)
    private var items: [Item]

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

        InsightsList(snapshot: snapshot)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    InsightsScopeMenu(
                        selectedRange: $selectedRange,
                        includesArchivedItems: $includesArchivedItems
                    )

                    StallyLinkShareButton(
                        link: .destination(.insights),
                        title: "Share Insights Link"
                    )
                }
            }
    }
}
