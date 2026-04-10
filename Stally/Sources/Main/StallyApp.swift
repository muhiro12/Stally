//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import Foundation
import MHPlatform
import MHUI
import SwiftUI

@main
struct StallyApp: App {
    nonisolated private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private let sharedAssembly: StallyAppAssembly?

    var body: some Scene {
        WindowGroup {
            if let sharedAssembly {
                StallyRootView()
                    .stallyAppAssembly(sharedAssembly)
                    .mhAppRuntimeBootstrap(sharedAssembly.bootstrap)
            } else {
                Color.clear
            }
        }
    }

    @MainActor
    init() {
        guard Self.isRunningTests == false else {
            sharedAssembly = nil
            return
        }

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
