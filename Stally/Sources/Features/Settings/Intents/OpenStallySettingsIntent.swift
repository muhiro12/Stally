//
//  OpenStallySettingsIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallySettingsIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Settings", table: "AppIntents")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let description = IntentDescription(
        .init("Open Stally to Settings.", table: "AppIntents")
    )
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.settings))
        return .result()
    }
}
