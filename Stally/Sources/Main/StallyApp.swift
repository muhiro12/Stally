//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import Foundation
import MHUI
import MHAppRuntimeCore
import MHLogging
import SwiftUI

@main
struct StallyApp: App {
    nonisolated private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private let sharedAssembly: StallyAppAssembly?
    private let startupLogger = Self.logger(category: "AppStartup")

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
