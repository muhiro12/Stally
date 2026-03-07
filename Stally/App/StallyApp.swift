//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import MHUI
import MHPlatform
import StallyLibrary
import SwiftData
import SwiftUI

@main
struct StallyApp: App {
    private let sharedModelContainer: ModelContainer
    private let sharedAppRuntime: MHAppRuntime
    private let sharedDeepLinkInbox: MHObservableDeepLinkInbox
    private let startupLogger = Self.logger(category: "AppStartup")

    var body: some Scene {
        WindowGroup {
            StallyRootView()
                .modelContainer(sharedModelContainer)
                .tint(StallyDesign.tint)
                .mhTheme(MHTheme.standard())
                .environment(sharedAppRuntime)
                .environment(sharedDeepLinkInbox)
        }
    }

    @MainActor
    init() {
        startupLogger.notice("app startup began")

        let bootstrap = StallyAppBootstrap.make()

        sharedModelContainer = bootstrap.modelContainer
        sharedAppRuntime = bootstrap.appRuntime
        sharedDeepLinkInbox = bootstrap.deepLinkInbox

        startupLogger.notice("startup dependencies ready")
    }
}
