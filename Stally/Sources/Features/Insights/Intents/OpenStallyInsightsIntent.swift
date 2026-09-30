//
//  OpenStallyInsightsIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyInsightsIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Insights", table: "AppIntents")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let description = IntentDescription(
        .init("Open Stally to Insights.", table: "AppIntents")
    )
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.insights))
        return .result()
    }
}
