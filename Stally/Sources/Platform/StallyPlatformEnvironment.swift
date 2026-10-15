//
//  StallyPlatformEnvironment.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import MHPlatform
import SwiftData

struct StallyPlatformEnvironment {
    enum PersistenceStatus: Equatable {
        case local
        case cloudKit
        case cloudKitUnavailable
        case temporaryLocal
    }

    let logging: MHLoggingBootstrap
    let modelContainer: ModelContainer
    let searchIndex: StallySearchIndexCoordinator
    let persistenceStatus: PersistenceStatus
    let routeInbox: StallyRouteInbox
    let routePipeline: StallyRoutePipeline
    let runtimeBootstrap: MHAppRuntimeBootstrap
}
