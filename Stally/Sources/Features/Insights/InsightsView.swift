//
//  InsightsView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct InsightsView: View {
    @Environment(\.calendar)
    private var calendar

    let items: [Item]

    @State private var selectedRange: InsightsRange = .thirtyDays
    @State private var includesArchivedItems = false

    private var options: InsightsOptions {
        .init(
            range: selectedRange,
            includesArchivedItems: includesArchivedItems
        )
    }

    private var snapshot: InsightsSnapshot {
        InsightsOperations.snapshot(
            for: items,
            options: options,
            calendar: calendar
        )
    }

    var body: some View {
        NavigationStack {
            InsightsList(
                snapshot: snapshot,
                selectedRange: $selectedRange,
                includesArchivedItems: $includesArchivedItems
            )
            .navigationTitle("Insights")
        }
    }
}
