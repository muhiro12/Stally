//
//  OpenStallyInsightsIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyInsightsIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Insights", table: "AppIntents")
    static let description = IntentDescription(
        .init("Open Stally to Insights.", table: "AppIntents")
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.insights))
        return .result()
    }
}
