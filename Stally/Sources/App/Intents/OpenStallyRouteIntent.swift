//
//  OpenStallyRouteIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import Foundation

struct OpenStallyRouteIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Stally Route", table: "AppIntents")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: "URL")
    private var url: URL

    init() {
        // Required by AppIntent.
    }

    init(url: URL) {
        self.url = url
    }

    @MainActor
    func perform() -> some IntentResult {
        StallyIntentRouteStore.store(url)
        return .result()
    }
}
