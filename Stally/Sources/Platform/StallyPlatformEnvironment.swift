//
//  StallyPlatformEnvironment.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import MHPlatform
import SwiftData
import SwiftUI

typealias StallyRouteInbox = MHObservableRouteInbox<StallyLink>
typealias StallyRoutePipeline = MHAppRoutePipeline<StallyLink>

struct StallyPlatformEnvironment {
    let logging: MHLoggingBootstrap
    let modelContainer: ModelContainer
    let routeInbox: StallyRouteInbox
    let routePipeline: StallyRoutePipeline
    let runtimeBootstrap: MHAppRuntimeBootstrap
}

extension View {
    func stallyPlatformEnvironment(
        _ environment: StallyPlatformEnvironment
    ) -> some View {
        stallyBasePlatformEnvironment(environment)
            .mhAppRuntimeBootstrap(environment.runtimeBootstrap)
    }

    func stallyPreviewPlatformEnvironment(
        _ environment: StallyPlatformEnvironment
    ) -> some View {
        stallyBasePlatformEnvironment(environment)
            .mhAppRuntimeEnvironment(environment.runtimeBootstrap)
    }

    private func stallyBasePlatformEnvironment(
        _ environment: StallyPlatformEnvironment
    ) -> some View {
        modelContainer(environment.modelContainer)
            .environment(environment.logging)
            .environment(environment.routeInbox)
            .environment(environment.routePipeline)
    }
}
