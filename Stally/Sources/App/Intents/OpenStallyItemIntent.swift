//
//  OpenStallyItemIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyItemIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Item", table: "AppIntents")
    static let description = IntentDescription("Open Stally to an item detail.")
    static let openAppWhenRun = true

    @Parameter(title: "Item")
    private var item: StallyItemEntity

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouter.shared.open(.item(item.uuid))
        return .result()
    }
}
