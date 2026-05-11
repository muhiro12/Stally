//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import MHPlatform
import MHUI
import SwiftUI

@main
struct StallyApp: App {
    private let sharedAssembly: StallyAppAssembly

    var body: some Scene {
        WindowGroup {
            StallyRootView()
                .stallyAppAssembly(sharedAssembly)
                .mhAppRuntimeBootstrap(sharedAssembly.bootstrap)
        }
    }

    @MainActor
    init() {
        let logging = StallyDiagnostics.makeLoggingBootstrap(
            configuration: StallyAppConfiguration.runtimeConfiguration
        )
        let startupLogger = logging.logger(category: "AppStartup")

        startupLogger.notice("app startup began")
        do {
            sharedAssembly = try StallyAppAssemblyFactory.makeLive(
                logging: logging
            )
        } catch {
            startupLogger.critical(
                "persistent model container initialization failed",
                metadata: [
                    "error": String(describing: error)
                ]
            )
            preconditionFailure(
                "Failed to initialize the Stally model container: \(error)"
            )
        }

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
