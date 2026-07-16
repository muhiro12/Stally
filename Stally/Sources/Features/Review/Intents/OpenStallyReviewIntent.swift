//
//  OpenStallyReviewIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyReviewIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Review", table: "AppIntents")
    static let description = IntentDescription(
        .init("Open Stally to Review.", table: "AppIntents")
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.review))
        return .result()
    }
}
