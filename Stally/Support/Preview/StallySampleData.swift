import MHPlatform
import StallyLibrary
import SwiftData
import SwiftUI

struct StallySampleData: PreviewModifier {
    struct Context {
        let modelContainer: ModelContainer
        let appRuntime: MHAppRuntime
        let deepLinkInbox: MHObservableDeepLinkInbox
    }

    static func makeSharedContext() throws -> Context {
        try makeContext(seedSampleData: true)
    }

    func body(
        content: Content,
        context: Context
    ) -> some View {
        content
            .modelContainer(context.modelContainer)
            .environment(context.appRuntime)
            .environment(context.deepLinkInbox)
    }
}

struct StallyEmptySampleData: PreviewModifier {
    typealias Context = StallySampleData.Context

    static func makeSharedContext() throws -> Context {
        try StallySampleData.makeContext(seedSampleData: false)
    }

    func body(
        content: Content,
        context: Context
    ) -> some View {
        content
            .modelContainer(context.modelContainer)
            .environment(context.appRuntime)
            .environment(context.deepLinkInbox)
    }
}

private extension StallySampleData {
    static func makeContext(
        seedSampleData: Bool
    ) throws -> Context {
        let modelContainer = try ModelContainer(
            for: Item.self,
            Mark.self,
            configurations: .init(
                isStoredInMemoryOnly: true
            )
        )

        if seedSampleData {
            try? ItemService.seedSampleData(
                context: modelContainer.mainContext,
                ifEmptyOnly: true
            )
        }

        let appRuntime = MainActor.assumeIsolated {
            MHAppRuntime(
                configuration: StallyAppConfiguration.runtimeConfiguration
            )
        }

        return .init(
            modelContainer: modelContainer,
            appRuntime: appRuntime,
            deepLinkInbox: .init()
        )
    }
}
