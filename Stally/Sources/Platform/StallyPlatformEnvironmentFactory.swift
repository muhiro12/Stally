//
//  StallyPlatformEnvironmentFactory.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import Foundation
import MHPlatform
import SwiftData

enum StallyPlatformEnvironmentFactory {
    @MainActor
    static func make(
        modelContainer: ModelContainer,
        platformMode: StallyPlatformMode,
        logging: MHLoggingBootstrap,
        persistenceStatus: StallyPlatformEnvironment.PersistenceStatus
    ) -> StallyPlatformEnvironment {
        let routeInbox = makeRouteInbox()
        let routePipeline = makeRoutePipeline(
            routeInbox: routeInbox,
            logging: logging
        )
        StallyIntentRouteStore.registerLiveRoutePipeline(routePipeline)

        return .init(
            logging: logging,
            modelContainer: modelContainer,
            searchIndex: StallySearchIndexCoordinator(
                modelContainer: modelContainer,
                scope: searchIndexScope(modelContainer: modelContainer, platformMode: platformMode),
                logging: logging
            ),
            persistenceStatus: persistenceStatus,
            routeInbox: routeInbox,
            routePipeline: routePipeline,
            runtimeBootstrap: makeRuntimeBootstrap(
                configuration: makeAppConfiguration(for: platformMode),
                routePipeline: routePipeline
            )
        )
    }

    private static func searchIndexScope(
        modelContainer: ModelContainer,
        platformMode: StallyPlatformMode
    ) -> StallySearchIndexCoordinator.Scope {
        if case .preview = platformMode {
            return .disabled
        }
        guard modelContainer.configurations.contains(where: \.isStoredInMemoryOnly) else {
            return .production
        }
        #if DEBUG
        let arguments = CommandLine.arguments
        if let position = arguments.firstIndex(of: "--stally-search-index-test-namespace"),
           arguments.indices.contains(position + 1),
           let identifier = UUID(uuidString: arguments[position + 1]) {
            return .test(identifier)
        }
        #endif
        return .disabled
    }

    private static func makeAppConfiguration(
        for platformMode: StallyPlatformMode
    ) -> MHAppConfiguration {
        .init(
            subscriptionProductIDs: [
                StallyMonetizationConfiguration.subscriptionProductID
            ],
            nativeAdUnitID: StallyMonetizationConfiguration.nativeAdUnitID(
                for: platformMode
            ),
            showsLicenses: true,
            adsConsent: .init()
        )
    }

    @MainActor
    private static func makeRouteInbox() -> StallyRouteInbox {
        .init(
            isDuplicate: { route, otherRoute in
                route == otherRoute
            },
            onFailure: { _, error in
                assertionFailure(error.localizedDescription)
            }
        )
    }

    @MainActor
    private static func makeRoutePipeline(
        routeInbox: StallyRouteInbox,
        logging: MHLoggingBootstrap
    ) -> StallyRoutePipeline {
        let routeLogger = StallyLogging.logger(
            logging: logging,
            category: StallyLogging.Category.routeExecution,
            source: #fileID
        )
        let isDuplicate: MHRouteLifecycle<StallyLink>.DuplicatePredicate = { route, otherRoute in
            route == otherRoute
        }
        let parseRoute: StallyRoutePipeline.RouteParser = { incomingURL in
            switch StallyLinkOperations.parse(incomingURL) {
            case .supported(let link):
                link
            case .unsupported:
                nil
            }
        }
        let handleFailure: StallyRoutePipeline.FailureHandler = { error in
            handleRoutePipelineFailure(
                error,
                logger: routeLogger
            )
        }

        return MHAppRoutePipeline(
            routeLifecycle: MHRouteLifecycle<StallyLink>(
                logger: routeLogger,
                initialReadiness: false,
                isDuplicate: isDuplicate
            ),
            parse: parseRoute,
            routeInbox: routeInbox,
            pendingSources: pendingURLSources(),
            onFailure: handleFailure
        )
    }

    @MainActor
    private static func handleRoutePipelineFailure(
        _ error: any Error,
        logger: MHLogger
    ) {
        logger.error(
            "route_pipeline.failure",
            metadata: StallyLogging.errorMetadata(error)
        )
        assertionFailure(error.localizedDescription)
    }

    private static func pendingURLSources() -> [any MHDeepLinkURLSource] {
        var sources = [any MHDeepLinkURLSource]()

        if let intentRouteSource = StallyIntentRouteStore.source {
            sources.append(intentRouteSource)
        }

        return sources
    }

    @MainActor
    private static func makeRuntimeBootstrap(
        configuration: MHAppConfiguration,
        routePipeline: StallyRoutePipeline
    ) -> MHAppRuntimeBootstrap {
        .init(
            configuration: configuration,
            routePipeline: routePipeline,
            lifecyclePlan: .init(
                commonTasks: [
                    routePipeline.task(name: "synchronizePendingRoutes")
                ]
            )
        )
    }
}
