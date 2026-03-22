import MHAppRuntimeAds
import MHAppRuntimeCore
import MHAppRuntimeDefaults
import MHAppRuntimeLicenses
import MHPreferences
import MHRouteExecution
import Observation
import StallyLibrary
import SwiftData
import SwiftUI

// swiftlint:disable file_types_order one_declaration_per_file
@MainActor
@Observable
final class StallyAppAssembly {
    let modelContainer: ModelContainer
    let appModel: StallyAppModel
    let routeInbox: MHObservableRouteInbox<StallyRoute>
    let routePipeline: MHAppRoutePipeline<StallyRoute>
    let bootstrap: MHAppRuntimeBootstrap

    private init(
        modelContainer: ModelContainer,
        lifecyclePlanStyle: LifecyclePlanStyle
    ) {
        let appModel = StallyAppModel()
        let routeInbox = MHObservableRouteInbox<StallyRoute>()
        let configuration = StallyAppConfiguration.runtimeConfiguration
        let defaultsBundle = MHAppRuntimeDefaultsBundle(
            configuration: configuration
        )
        let adsBundle = MHAppRuntimeAdsBundle(
            configuration: configuration
        )
        let licensesBundle = MHAppRuntimeLicensesBundle(
            configuration: configuration
        )
        let runtime = MHAppRuntime(
            configuration: configuration,
            preferenceStore: defaultsBundle.preferenceStore,
            startStore: defaultsBundle.startStore,
            subscriptionSectionFactory:
                defaultsBundle.subscriptionSectionFactory,
            startAds: adsBundle.startAds,
            nativeAdFactory: adsBundle.nativeAdFactory,
            licensesFactory: licensesBundle.licensesFactory
        )
        let routePipeline = MHAppRoutePipeline(
            routeLifecycle: .init(
                logger: StallyApp.logger(category: "RoutePipeline"),
                initialReadiness: false,
                isDuplicate: ==
            ),
            using: StallyDeepLinking.codec(),
            routeInbox: routeInbox,
            pendingSources: []
        )

        self.modelContainer = modelContainer
        self.appModel = appModel
        self.routeInbox = routeInbox
        self.routePipeline = routePipeline
        self.bootstrap = .init(
            runtime: runtime,
            lifecyclePlan: lifecyclePlanStyle.makePlan(
                appModel: appModel,
                preferenceStore: runtime.preferenceStore,
                routePipeline: routePipeline
            ),
            routePipeline: routePipeline
        )
    }

    @MainActor
    static func make(
        modelContainer: ModelContainer,
        lifecyclePlanStyle: LifecyclePlanStyle
    ) -> StallyAppAssembly {
        .init(
            modelContainer: modelContainer,
            lifecyclePlanStyle: lifecyclePlanStyle
        )
    }

    @MainActor
    static func makeLiveAssembly() throws -> StallyAppAssembly {
        make(
            modelContainer: try ModelContainerFactory.shared(),
            lifecyclePlanStyle: .live
        )
    }

    static func makePreviewModelContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Item.self,
            Mark.self,
            configurations: .init(
                isStoredInMemoryOnly: true
            )
        )
    }
}
enum StallyAppAssemblyFactory {
    @MainActor
    static func makeLive() -> StallyAppAssembly {
        do {
            return try makeLiveAssembly()
        } catch {
            preconditionFailure(
                "Failed to initialize the Stally model container: \(error)"
            )
        }
    }

    @MainActor
    static func makePreview(
        seedSampleData: Bool
    ) throws -> StallyAppAssembly {
        let modelContainer = try StallyAppAssembly.makePreviewModelContainer()

        if seedSampleData {
            try? ItemService.seedSampleData(
                context: modelContainer.mainContext,
                ifEmptyOnly: true
            )
        }

        return StallyAppAssembly.make(
            modelContainer: modelContainer,
            lifecyclePlanStyle: .preview
        )
    }
}

private extension StallyAppAssemblyFactory {
    @MainActor
    static func makeLiveAssembly() throws -> StallyAppAssembly {
        try StallyAppAssembly.makeLiveAssembly()
    }
}

extension StallyAppAssembly {
    enum LifecyclePlanStyle {
        case live
        case preview

        func makePlan(
            appModel: StallyAppModel,
            preferenceStore: MHPreferenceStore,
            routePipeline: MHAppRoutePipeline<StallyRoute>
        ) -> MHAppRuntimeLifecyclePlan {
            let loadPreferencesTask = MHAppRuntimeTask(
                name: "loadPreferences"
            ) {
                appModel.loadReviewPreferencesIfNeeded(
                    from: preferenceStore
                )
                appModel.loadInsightsPreferencesIfNeeded(
                    from: preferenceStore
                )
            }

            switch self {
            case .live:
                return MHAppRuntimeLifecyclePlan(
                    startupTasks: [
                        loadPreferencesTask
                    ],
                    activeTasks: [
                        routePipeline.task(
                            name: "synchronizePendingRoutes"
                        )
                    ],
                    skipFirstActivePhase: true
                )
            case .preview:
                return MHAppRuntimeLifecyclePlan(
                    startupTasks: [
                        loadPreferencesTask
                    ]
                )
            }
        }
    }
}
extension View {
    func stallyAppAssembly(
        _ assembly: StallyAppAssembly
    ) -> some View {
        self
            .modelContainer(assembly.modelContainer)
            .tint(StallyDesign.tint)
            .environment(assembly.appModel)
            .environment(assembly)
    }
}
// swiftlint:enable file_types_order one_declaration_per_file
