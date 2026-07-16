//
//  OpenStallyItemIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyItemIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Item", table: "AppIntents")
    static let description = IntentDescription(
        .init("Open Stally to an item detail.", table: "AppIntents")
    )
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: .init("Item", table: "AppIntents"))
    private var item: StallyItemEntity

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(.item(item.uuid))
        return .result()
    }
}
