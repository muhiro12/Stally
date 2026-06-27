//
//  OpenStallyLibraryIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyLibraryIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Library", table: "AppIntents")
    static let description = IntentDescription("Open Stally to Library.")
    static let openAppWhenRun = true

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouter.shared.open(.destination(.library))
        return .result()
    }
}
