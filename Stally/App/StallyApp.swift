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
    private let sharedEnvironment: StallyPlatformEnvironment
    private let startupLogger = Self.logger(category: "AppStartup")

    var body: some Scene {
        WindowGroup {
            StallyRootView()
                .stallyPlatformEnvironment(sharedEnvironment)
        }
    }

    @MainActor
    init() {
        startupLogger.notice("app startup began")
        sharedEnvironment = StallyPlatformEnvironmentFactory.makeLive()

        startupLogger.notice("startup dependencies ready")
    }
}
