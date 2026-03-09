//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import MHUI
import MHPlatform
import SwiftUI

@main
struct StallyApp: App {
    private let sharedAssembly: StallyAppAssembly
    private let startupLogger = Self.logger(category: "AppStartup")

    var body: some Scene {
        WindowGroup {
            StallyRootView()
                .stallyAppAssembly(sharedAssembly)
                .mhAppRuntimeBootstrap(sharedAssembly.bootstrap)
        }
    }

    @MainActor
    init() {
        startupLogger.notice("app startup began")
        sharedAssembly = StallyAppAssemblyFactory.makeLive()

        startupLogger.notice("startup dependencies ready")

        do {
            try StallyTips.configure()
            startupLogger.notice("tip guidance ready")
        } catch {
            startupLogger.error(
                "tip guidance failed to configure: \(String(describing: error))"
            )
        }
    }
}
