//
//  OpenStallyDestinationIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

struct OpenStallyDestinationIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Stally Destination", table: "AppIntents")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let description = IntentDescription(
        .init("Open Stally to a major app destination.", table: "AppIntents")
    )
    static let supportedModes: IntentModes = .foreground
    static let isDiscoverable = false

    @Parameter(title: .init("Destination", table: "AppIntents"))
    private var destination: StallyDestinationIntentValue

    @MainActor
    func perform() async -> some IntentResult {
        await StallyIntentRouteOpener.store(
            .destination(destination.linkDestination)
        )
        return .result()
    }
}
