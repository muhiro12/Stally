//
//  OpenStallyBackupCenterIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyBackupCenterIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Backup Center", table: "AppIntents")
    static let description = IntentDescription("Open Stally to Backup Center.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouteOpener.store(.destination(.backupCenter))
        return .result()
    }
}
