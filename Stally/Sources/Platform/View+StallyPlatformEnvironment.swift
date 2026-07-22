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
            .tint(.accent)
            .environment(environment.logging)
            .environment(\.stallyPersistenceStatus, environment.persistenceStatus)
            .environment(environment.routeInbox)
            .environment(environment.routePipeline)
    }
}
