//
//  OpenStallyArchiveIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyArchiveIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Archive", table: "AppIntents")
    static let description = IntentDescription(
        .init("Open Stally to Archive.", table: "AppIntents")
    )
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.archive))
        return .result()
    }
}
