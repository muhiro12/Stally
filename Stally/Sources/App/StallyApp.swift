//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import AppIntents
import MHPlatform
import MHUI
import SwiftData
import SwiftUI
import TipKit

@main
struct StallyApp: App {
    private struct ModelContainerResolution {
        let modelContainer: ModelContainer
        let persistenceStatus: StallyPlatformEnvironment.PersistenceStatus
    }

    #if DEBUG
    private static let previewLaunchConfiguration = StallyPreviewLaunchConfiguration.current
    #endif

    private let platformEnvironment: StallyPlatformEnvironment

    var body: some Scene {
        WindowGroup {
            rootContent
                .stallyPlatformEnvironment(platformEnvironment)
                .mhTheme(.standard)
                .mhGlassPolicy(.automatic)
        }
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
        let logging = StallyLogging.makeBootstrap()
        let startupLogger = StallyLogging.logger(
            logging: logging,
            category: StallyLogging.Category.appStartup,
            source: #fileID
        )
        startupLogger.notice("startup.begin")
        Self.configureTips(startupLogger: startupLogger)

        let preferenceStore = MHPreferenceStore()
        let syncsWithCloudKit = preferenceStore.bool(for: \.isICloudOn)
        let modelContainerResolution = Self.makeModelContainer(
            syncsWithCloudKit: syncsWithCloudKit,
            startupLogger: startupLogger
        )
        let resolvedPlatformEnvironment = StallyPlatformEnvironmentFactory.make(
            modelContainer: modelContainerResolution.modelContainer,
            platformMode: .production,
            logging: logging,
            persistenceStatus: modelContainerResolution.persistenceStatus
        )
        platformEnvironment = resolvedPlatformEnvironment
        startupLogger.notice("startup.dependencies_ready")

        Self.registerDependencies(
            platformEnvironment,
            startupLogger: startupLogger
        )
        StallyShortcuts.updateAppShortcutParameters()
        startupLogger.notice("startup.ready")
    }
}

private extension StallyApp {
    static func configureTips(startupLogger: MHLogger) {
        do {
            try Tips.configure([
                .displayFrequency(.daily)
            ])
            startupLogger.notice("tipkit.configured")
        } catch {
            startupLogger.error(
                "tipkit.configuration_failed",
                metadata: StallyLogging.errorMetadata(error)
            )
        }
    }

    private static func makeModelContainer(
        syncsWithCloudKit: Bool,
        startupLogger: MHLogger
    ) -> ModelContainerResolution {
        #if DEBUG
        if let modelContainer = Self.previewLaunchConfiguration.modelContainer {
            startupLogger.notice("model_container.preview_created")
            return .init(
                modelContainer: modelContainer,
                persistenceStatus: .local
            )
        }
        #endif

        do {
            let modelContainer = try StallyModelContainerFactory.persistent(
                syncsWithCloudKit: syncsWithCloudKit
            )
            startupLogger.notice(
                syncsWithCloudKit
                    ? "model_container.cloudkit_created"
                    : "model_container.local_created"
            )
            return .init(
                modelContainer: modelContainer,
                persistenceStatus: syncsWithCloudKit ? .cloudKit : .local
            )
        } catch {
            guard syncsWithCloudKit else {
                startupLogger.critical(
                    "model_container.local_failed",
                    metadata: StallyLogging.errorMetadata(error)
                )
                fatalError("Could not create local ModelContainer: \(error)")
            }

            startupLogger.notice(
                "model_container.cloudkit_unavailable_falling_back_local",
                metadata: StallyLogging.errorMetadata(error)
            )
            return Self.makeLocalModelContainerAfterCloudKitFailure(
                startupLogger: startupLogger
            )
        }
    }

    private static func makeLocalModelContainerAfterCloudKitFailure(
        startupLogger: MHLogger
    ) -> ModelContainerResolution {
        do {
            let modelContainer = try StallyModelContainerFactory.persistent(
                syncsWithCloudKit: false
            )
            startupLogger.notice("model_container.local_created")
            return .init(
                modelContainer: modelContainer,
                persistenceStatus: .cloudKitUnavailable
            )
        } catch {
            startupLogger.critical(
                "model_container.local_failed",
                metadata: StallyLogging.errorMetadata(error)
            )
            fatalError("Could not create local ModelContainer: \(error)")
        }
    }

    @MainActor
    static func registerDependencies(
        _ platformEnvironment: StallyPlatformEnvironment,
        startupLogger: MHLogger
    ) {
        AppDependencyManager.shared.add {
            platformEnvironment.logging
        }
        AppDependencyManager.shared.add {
            platformEnvironment.modelContainer
        }
        startupLogger.notice("startup.dependencies_registered")
    }
}
