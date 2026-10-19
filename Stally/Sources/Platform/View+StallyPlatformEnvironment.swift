//
//  View+StallyPlatformEnvironment.swift
//  Stally
//
//  Created by Codex on 2026/07/22.
//

import MHPlatform
import SwiftData
import SwiftUI

extension View {
    func stallyPlatformEnvironment(
        _ environment: StallyPlatformEnvironment
    ) -> some View {
        modifier(StallySearchIndexSyncModifier())
            .stallyBasePlatformEnvironment(environment)
            .mhAppRuntimeEnvironment(environment.runtimeBootstrap)
            .mhAppRuntimeLifecycle(
                runtime: environment.runtimeBootstrap.runtime,
                plan: environment.runtimeBootstrap.lifecyclePlan
            )
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
        modifier(StallyUpdateRequiredModifier())
            .modelContainer(environment.modelContainer)
            .tint(.accent)
            .environment(environment.logging)
            .environment(\.stallyPersistenceStatus, environment.persistenceStatus)
            .environment(environment.routeInbox)
            .environment(environment.routePipeline)
            .environment(environment.searchIndex)
            .environment(environment.remoteUpdates)
    }
}
