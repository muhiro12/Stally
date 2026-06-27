//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import AppIntents
import MHUI
import OSLog
import SwiftData
import SwiftUI

@main
struct StallyApp: App {
    private static let logger = Logger(
        subsystem: "com.muhiro12.Stally",
        category: "ModelContainer"
    )

    #if DEBUG
    private static let previewLaunchConfiguration = StallyPreviewLaunchConfiguration.current
    #endif

    let sharedModelContainer: ModelContainer

    var body: some Scene {
        WindowGroup {
            rootContent
                .mhTheme(.standard)
                .mhGlassPolicy(.automatic)
        }
        .modelContainer(sharedModelContainer)
    }

    @ViewBuilder private var rootContent: some View {
        #if DEBUG
        if let route = Self.previewLaunchConfiguration.route {
            ContentView(initialPreviewRoute: route)
        } else {
            ContentView()
        }
        #else
        ContentView()
        #endif
    }

    @MainActor
    init() {
        let modelContainer = Self.makeModelContainer()
        sharedModelContainer = modelContainer
        Self.registerDependencies(modelContainer: modelContainer)
        StallyShortcuts.updateAppShortcutParameters()
    }
}

private extension StallyApp {
    static func makeModelContainer() -> ModelContainer {
        #if DEBUG
        if let modelContainer = Self.previewLaunchConfiguration.modelContainer {
            return modelContainer
        }
        #endif

        do {
            return try StallyModelContainerFactory.persistent()
        } catch {
            Self.logger.notice(
                """
                model_container.cloudkit_unavailable_falling_back_local: \
                \(error.localizedDescription, privacy: .public)
                """
            )

            do {
                return try StallyModelContainerFactory.persistent(syncsWithCloudKit: false)
            } catch {
                fatalError("Could not create local ModelContainer: \(error)")
            }
        }
    }

    @MainActor
    static func registerDependencies(modelContainer: ModelContainer) {
        AppDependencyManager.shared.add {
            modelContainer
        }
    }
}
