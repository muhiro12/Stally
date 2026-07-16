//
//  OpenStallySettingsIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallySettingsIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Settings", table: "AppIntents")
    static let description = IntentDescription(
        .init("Open Stally to Settings.", table: "AppIntents")
    )
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.settings))
        return .result()
    }
}
