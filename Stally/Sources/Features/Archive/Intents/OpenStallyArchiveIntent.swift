//
//  OpenStallyArchiveIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyArchiveIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Archive", table: "AppIntents")
    static let description = IntentDescription("Open Stally to Archive.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouteOpener.store(.destination(.archive))
        return .result()
    }
}
