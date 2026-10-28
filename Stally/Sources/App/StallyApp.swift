import AppIntents
import MHPlatform
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

@main
struct StallyApp: App {
    private let container: ModelContainer?
    private let startupError: String?
    private let runtimeBootstrap: MHAppRuntimeBootstrap
    private let updates: RemoteUpdateOperations

    var body: some Scene {
        WindowGroup {
            if let container {
                LibraryView()
                    .modelContainer(container)
                    .environment(updates)
                    .mhTheme(.standard)
                    .mhAppRuntimeEnvironment(runtimeBootstrap)
                    .mhAppRuntimeLifecycle(
                        runtime: runtimeBootstrap.runtime,
                        plan: runtimeBootstrap.lifecyclePlan
                    )
                    .task {
                        _ = try? await updates.prepare()
                    }
            } else {
                ContentUnavailableView {
                    Label(
                        "Stally could not open its records",
                        systemImage: "externaldrive.badge.exclamationmark"
                    )
                } description: {
                    Text(startupError ?? "")
                        .textSelection(.enabled)
                }
            }
        }
    }

    init() {
        #if os(iOS)
        MHTheme.standard.configureNativeAppearance()
        #endif
        let logging = StallyLogging.makeBootstrap()
        let logger = StallyLogging.logger(logging: logging, category: "Persistence", source: #fileID)
        let updateOperations = StallyRemoteUpdateConfiguration.makeOperations()
        updates = updateOperations
        runtimeBootstrap = .init(
            configuration: .init(
                subscriptionProductIDs: [StallyMonetizationConfiguration.subscriptionProductID],
                nativeAdUnitID: StallyMonetizationConfiguration.nativeAdUnitID(for: .production),
                showsLicenses: true,
                adsConsent: .init()
            )
        )
        do {
            let modelContainer = try Self.makeContainer()
            modelContainer.mainContext.autosaveEnabled = false
            container = modelContainer
            startupError = nil
            AppDependencyManager.shared.add { modelContainer }
            AppDependencyManager.shared.add { updateOperations }
            logger.notice("model_container.opened")
        } catch {
            container = nil
            startupError = error.localizedDescription
            logger.error("model_container.open_failed", metadata: StallyLogging.errorMetadata(error))
        }
    }

    private static func makeContainer() throws -> ModelContainer {
        #if DEBUG
        let defaults = UserDefaults.standard
        defaults.register(defaults: ["development.automaticallySeedRecords": true])
        if !defaults.bool(forKey: "development.useSharedStore") {
            return try StallyDevelopmentStore.open(
                automaticallySeed: defaults.bool(forKey: "development.automaticallySeedRecords")
            )
        }
        #endif
        return try StallyModelContainerFactory.persistent()
    }
}
