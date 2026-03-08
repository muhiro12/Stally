import SwiftUI

struct StallyEmptySampleData: PreviewModifier {
    typealias Context = StallyPlatformEnvironment

    static func makeSharedContext() throws -> Context {
        try StallyPlatformEnvironmentFactory.makePreview(
            seedSampleData: false
        )
    }

    func body(
        content: Content,
        context: Context
    ) -> some View {
        content.stallyPlatformEnvironment(context)
    }
}
