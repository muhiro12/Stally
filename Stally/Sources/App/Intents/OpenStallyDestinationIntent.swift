//
//  OpenStallyDestinationIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyDestinationIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Stally Destination", table: "AppIntents")
    static let description = IntentDescription("Open Stally to a major app destination.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: "Destination")
    private var destination: StallyDestinationIntentValue

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(
            .destination(destination.linkDestination)
        )
        return .result()
    }
}
