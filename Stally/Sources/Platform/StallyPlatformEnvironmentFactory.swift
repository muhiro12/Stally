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
        logging: MHLoggingBootstrap
    ) -> StallyPlatformEnvironment {
        let routeInbox = makeRouteInbox()
        let routePipeline = makeRoutePipeline(
            routeInbox: routeInbox,
            logging: logging
        )

        return .init(
            logging: logging,
            modelContainer: modelContainer,
            routeInbox: routeInbox,
            routePipeline: routePipeline,
            runtimeBootstrap: makeRuntimeBootstrap(
                configuration: makeAppConfiguration(for: platformMode),
                routePipeline: routePipeline
            )
        )
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
            showsLicenses: true
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
            runtimeOnlyConfiguration: configuration,
            routePipeline: routePipeline,
            lifecyclePlan: .init(
                commonTasks: [
                    routePipeline.task(name: "synchronizePendingRoutes")
                ]
            )
        )
    }
}
