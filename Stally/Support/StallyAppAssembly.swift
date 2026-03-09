import MHUI
import MHPlatform
import Observation
import StallyLibrary
import SwiftData
import SwiftUI

@MainActor
@Observable
final class StallyAppAssembly {
    let modelContainer: ModelContainer
    let navigationState: StallyRootNavigationState
    let routeInbox: MHObservableRouteInbox<StallyRoute>
    let deepLinkInbox: MHObservableDeepLinkInbox
    let bootstrap: MHAppRuntimeBootstrap

    fileprivate init(
        modelContainer: ModelContainer,
        lifecyclePlanStyle: LifecyclePlanStyle
    ) {
        let navigationState = StallyRootNavigationState()
        let routeInbox = MHObservableRouteInbox<StallyRoute>()
        let deepLinkInbox = MHObservableDeepLinkInbox()
        let runtime = MHAppRuntime(
            configuration: StallyAppConfiguration.runtimeConfiguration
        )
        let routePipeline = MHAppRoutePipeline(
            routeLifecycle: .init(
                logger: StallyApp.logger(category: "RoutePipeline"),
                initialReadiness: false,
                isDuplicate: ==
            ),
            using: StallyDeepLinking.codec(),
            routeInbox: routeInbox,
            pendingSources: [],
            inbox: deepLinkInbox
        )

        self.modelContainer = modelContainer
        self.navigationState = navigationState
        self.routeInbox = routeInbox
        self.deepLinkInbox = deepLinkInbox
        self.bootstrap = .init(
            runtime: runtime,
            lifecyclePlan: lifecyclePlanStyle.makePlan(
                navigationState: navigationState,
                preferenceStore: runtime.preferenceStore,
                routePipeline: routePipeline
            ),
            routePipeline: routePipeline
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
        let modelContainer = try makePreviewModelContainer()

        if seedSampleData {
            try? ItemService.seedSampleData(
                context: modelContainer.mainContext,
                ifEmptyOnly: true
            )
        }

        return .init(
            modelContainer: modelContainer,
            lifecyclePlanStyle: .preview
        )
    }
}

private extension StallyAppAssemblyFactory {
    @MainActor
    static func makeLiveAssembly() throws -> StallyAppAssembly {
        try .init(
            modelContainer: ModelContainerFactory.shared(),
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

extension StallyAppAssembly {
    enum LifecyclePlanStyle {
        case live
        case preview

        func makePlan(
            navigationState: StallyRootNavigationState,
            preferenceStore: MHPreferenceStore,
            routePipeline: MHAppRoutePipeline<StallyRoute>
        ) -> MHAppRuntimeLifecyclePlan {
            let loadPreferencesTask = MHAppRuntimeTask(
                name: "loadPreferences"
            ) {
                navigationState.loadReviewPreferencesIfNeeded(
                    from: preferenceStore
                )
                navigationState.loadInsightsPreferencesIfNeeded(
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
            .mhTheme(MHTheme.standard())
            .environment(assembly)
            .environment(assembly.navigationState)
            .environment(assembly.routeInbox)
            .environment(assembly.deepLinkInbox)
            .environment(assembly.bootstrap.runtime)
    }
}
