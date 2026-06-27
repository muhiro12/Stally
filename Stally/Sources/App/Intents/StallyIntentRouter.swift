//
//  StallyIntentRouter.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import Observation

@MainActor
@Observable
final class StallyIntentRouter {
    static let shared = StallyIntentRouter()

    var pendingRoute: StallyIntentRoute?

    private init() {
        // Shared router for App Intent handoff into the main scene.
    }

    func open(_ link: StallyLink) {
        pendingRoute = .init(link: link)
    }

    func consume(_ route: StallyIntentRoute) {
        guard pendingRoute == route else {
            return
        }

        pendingRoute = nil
    }
}
