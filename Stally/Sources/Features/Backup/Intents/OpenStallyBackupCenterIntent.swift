//
//  OpenStallyBackupCenterIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyBackupCenterIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Import & Export", table: "AppIntents")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let description = IntentDescription(
        .init("Open Stally to Import & Export.", table: "AppIntents")
    )
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.destination(.backupCenter))
        return .result()
    }
}
