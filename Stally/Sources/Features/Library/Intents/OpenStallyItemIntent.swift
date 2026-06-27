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
    static let isDiscoverable = false

    @Parameter(title: "Item")
    private var item: StallyItemEntity

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouteOpener.store(.item(item.uuid))
        return .result()
    }
}
