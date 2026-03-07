//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import MHPlatform
import SwiftUI

@main
struct StallyApp: App {
    private let sharedAppRuntime: MHAppRuntime
    private let sharedDeepLinkInbox: MHObservableDeepLinkInbox
    private let startupLogger = Self.logger(category: "AppStartup")

    var body: some Scene {
        WindowGroup {
            StallyRootView()
                .environment(sharedAppRuntime)
                .environment(sharedDeepLinkInbox)
        }
    }

    @MainActor
    init() {
        startupLogger.notice("app startup began")

        let bootstrap = StallyAppBootstrap.make()

        sharedAppRuntime = bootstrap.appRuntime
        sharedDeepLinkInbox = bootstrap.deepLinkInbox

        startupLogger.notice("startup dependencies ready")
    }
}
