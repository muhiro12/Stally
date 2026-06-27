//
//  OpenStallyInsightsIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyInsightsIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Insights", table: "AppIntents")
    static let description = IntentDescription("Open Stally to Insights.")
    static let openAppWhenRun = true

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouteOpener.store(.destination(.insights))
        return .result()
    }
}
