//
//  OpenStallyLibraryIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyLibraryIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Library", table: "AppIntents")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let description = IntentDescription(
        .init("Open Stally to Library.", table: "AppIntents")
    )
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.library))
        return .result()
    }
}
