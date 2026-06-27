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

    @Parameter(title: "Destination")
    private var destination: StallyDestinationIntentValue

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouter.shared.open(.destination(destination.linkDestination))
        return .result()
    }
}
