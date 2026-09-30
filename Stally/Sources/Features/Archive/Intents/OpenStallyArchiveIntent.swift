//
//  OpenStallyArchiveIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyArchiveIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Archive", table: "AppIntents")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let description = IntentDescription(
        .init("Open Stally to Archive.", table: "AppIntents")
    )
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.archive))
        return .result()
    }
}
