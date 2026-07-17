//
//  StallyPreviewContainer.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

#if DEBUG
import MHUI
import SwiftData
import SwiftUI

@MainActor
struct StallyPreviewContainer<Content: View>: View {
    private let container: ModelContainer
    private let platformEnvironment: StallyPlatformEnvironment
    private let content: ([Item]) -> Content

    var body: some View {
        content(StallyPreviewData.items(in: container))
            .stallyPreviewPlatformEnvironment(platformEnvironment)
            .environment(\.timeZone, StallyPreviewData.timeZone)
            .mhTheme(.standard)
            .mhGlassPolicy(.disabled)
    }

    init(
        @ViewBuilder content: @escaping ([Item]) -> Content
    ) {
        let resolvedContainer = StallyPreviewData.makeContainer(for: .typical)
        container = resolvedContainer
        platformEnvironment = Self.makePlatformEnvironment(
            modelContainer: resolvedContainer
        )
        self.content = content
    }

    init(
        _ scenario: StallyPreviewScenario,
        @ViewBuilder content: @escaping ([Item]) -> Content
    ) {
        let resolvedContainer = StallyPreviewData.makeContainer(for: scenario)
        container = resolvedContainer
        platformEnvironment = Self.makePlatformEnvironment(
            modelContainer: resolvedContainer
        )
        self.content = content
    }

    private static func makePlatformEnvironment(
        modelContainer: ModelContainer
    ) -> StallyPlatformEnvironment {
        StallyPlatformEnvironmentFactory.make(
            modelContainer: modelContainer,
            platformMode: .preview,
            logging: StallyLogging.makeBootstrap()
        )
    }
}
#endif
