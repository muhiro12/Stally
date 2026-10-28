import AppIntents
import MHPlatform
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

@main
struct StallyApp: App {
    @State private var showingDiagnostics = false

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
                startupFailure
            }
        }
    }

    private var startupFailure: some View {
        ContentUnavailableView {
            Label(
                "Stally could not open its records",
                systemImage: "externaldrive.badge.exclamationmark"
            )
        } description: {
            Text(startupError ?? "")
                .textSelection(.enabled)
        } actions: {
            Button("Debug", systemImage: "ladybug") {
                showingDiagnostics = true
            }
        }
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView(container: nil, startupError: startupError)
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
        StallyDevelopmentPreferences.register(in: defaults)
        if !defaults.bool(forKey: StallyDevelopmentPreferences.useSharedStoreKey) {
            return try StallyDevelopmentStore.open(
                automaticallySeed: defaults.bool(forKey: StallyDevelopmentPreferences.automaticallySeedRecordsKey)
            )
        }
        #endif
        return try StallyModelContainerFactory.persistent()
    }
}
