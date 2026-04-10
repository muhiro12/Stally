import MHPlatform
import MHUI
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
    let logging: MHLoggingBootstrap
    let routeInbox: MHObservableRouteInbox<StallyRoute>
    let routePipeline: MHAppRoutePipeline<StallyRoute>
    let bootstrap: MHAppRuntimeBootstrap

    private init(
        modelContainer: ModelContainer,
        lifecyclePlanStyle: LifecyclePlanStyle,
        logging: MHLoggingBootstrap? = nil
    ) {
        let appModel = StallyAppModel()
        let routeInbox = MHObservableRouteInbox<StallyRoute>()
        let configuration = lifecyclePlanStyle.configuration
        let logging = logging ?? StallyDiagnostics.makeLoggingBootstrap(
            configuration: configuration
        )

        let routePipeline = MHAppRoutePipeline(
            routeLifecycle: .init(
                logger: logging.logger(category: "RoutePipeline"),
                initialReadiness: false,
                isDuplicate: ==
            ),
            using: StallyDeepLinking.codec(),
            routeInbox: routeInbox,
            pendingSources: [],
            failureLogger: logging.logger(category: "DeepLink")
        )
        let provisionalBootstrap = MHAppRuntimeBootstrap(
            configuration: configuration,
            lifecyclePlan: .empty,
            routePipeline: routePipeline
        )
        let lifecyclePlan = lifecyclePlanStyle.makePlan(
            appModel: appModel,
            preferenceStore: provisionalBootstrap.runtime.preferenceStore,
            routePipeline: routePipeline
        )

        self.modelContainer = modelContainer
        self.appModel = appModel
        self.logging = logging
        self.routeInbox = routeInbox
        self.routePipeline = routePipeline
        self.bootstrap = .init(
            runtime: provisionalBootstrap.runtime,
            lifecyclePlan: lifecyclePlan,
            routePipeline: routePipeline
        )
    }

    @MainActor
    static func make(
        modelContainer: ModelContainer,
        lifecyclePlanStyle: LifecyclePlanStyle,
        logging: MHLoggingBootstrap? = nil
    ) -> StallyAppAssembly {
        .init(
            modelContainer: modelContainer,
            lifecyclePlanStyle: lifecyclePlanStyle,
            logging: logging
        )
    }

    @MainActor
    static func makeLiveAssembly(
        logging: MHLoggingBootstrap
    ) throws -> StallyAppAssembly {
        make(
            modelContainer: try ModelContainerFactory.shared(),
            lifecyclePlanStyle: .live,
            logging: logging
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
    static func makeLive(
        logging: MHLoggingBootstrap
    ) throws -> StallyAppAssembly {
        try StallyAppAssembly.makeLiveAssembly(logging: logging)
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

extension StallyAppAssembly {
    enum LifecyclePlanStyle {
        case live
        case preview

        var configuration: MHAppConfiguration {
            switch self {
            case .live:
                StallyAppConfiguration.runtimeConfiguration
            case .preview:
                StallyAppConfiguration.previewConfiguration
            }
        }

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
                appModel.loadDebugModeIfNeeded(
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
            .mhTheme(.standard)
            .mhGlassPolicy(.automatic)
            .environment(assembly.appModel)
            .environment(assembly)
    }
}
// swiftlint:enable file_types_order one_declaration_per_file
