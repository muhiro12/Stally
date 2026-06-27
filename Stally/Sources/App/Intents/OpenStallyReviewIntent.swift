//
//  OpenStallyReviewIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyReviewIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Review", table: "AppIntents")
    static let description = IntentDescription("Open Stally to Review.")
    static let openAppWhenRun = true

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouter.shared.open(.destination(.review))
        return .result()
    }
}
