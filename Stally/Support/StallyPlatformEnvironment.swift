import MHUI
import MHPlatform
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyPlatformEnvironment {
    let modelContainer: ModelContainer
    let appRuntime: MHAppRuntime
    let deepLinkInbox: MHObservableDeepLinkInbox
}

enum StallyPlatformEnvironmentFactory {
    @MainActor
    static func makeLive() -> StallyPlatformEnvironment {
        do {
            return try makeLiveEnvironment()
        } catch {
            preconditionFailure(
                "Failed to initialize the Stally model container: \(error)"
            )
        }
    }

    @MainActor
    static func makePreview(
        seedSampleData: Bool
    ) throws -> StallyPlatformEnvironment {
        let modelContainer = try makePreviewModelContainer()

        if seedSampleData {
            try? ItemService.seedSampleData(
                context: modelContainer.mainContext,
                ifEmptyOnly: true
            )
        }

        return makeEnvironment(
            modelContainer: modelContainer
        )
    }
}

private extension StallyPlatformEnvironmentFactory {
    @MainActor
    static func makeLiveEnvironment() throws -> StallyPlatformEnvironment {
        try makeEnvironment(
            modelContainer: ModelContainerFactory.shared()
        )
    }

    @MainActor
    static func makeEnvironment(
        modelContainer: ModelContainer
    ) -> StallyPlatformEnvironment {
        .init(
            modelContainer: modelContainer,
            appRuntime: .init(
                configuration: StallyAppConfiguration.runtimeConfiguration
            ),
            deepLinkInbox: .init()
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

extension View {
    func stallyPlatformEnvironment(
        _ environment: StallyPlatformEnvironment
    ) -> some View {
        self
            .modelContainer(environment.modelContainer)
            .tint(StallyDesign.tint)
            .mhTheme(MHTheme.standard())
            .environment(environment.appRuntime)
            .environment(environment.deepLinkInbox)
    }
}
