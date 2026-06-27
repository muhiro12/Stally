//
//  StallyShortcuts.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct StallyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenStallyLibraryIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Open Library in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Open Library", table: "AppIntents"),
            systemImageName: "tray"
        )
        AppShortcut(
            intent: CreateStallyItemIntent(),
            phrases: [
                "Create item in \(.applicationName)",
                "Add item in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Create Item", table: "AppIntents"),
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: MarkStallyItemTodayIntent(),
            phrases: [
                "Mark item in \(.applicationName)",
                "Mark today in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Mark Today", table: "AppIntents"),
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: OpenStallyReviewIntent(),
            phrases: [
                "Open Review in \(.applicationName)",
                "Review items in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Open Review", table: "AppIntents"),
            systemImageName: "text.badge.checkmark"
        )
        AppShortcut(
            intent: OpenStallyInsightsIntent(),
            phrases: [
                "Open Insights in \(.applicationName)",
                "Read collection patterns in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Open Insights", table: "AppIntents"),
            systemImageName: "chart.line.uptrend.xyaxis"
        )
    }
}
