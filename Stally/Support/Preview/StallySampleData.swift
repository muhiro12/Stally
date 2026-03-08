import SwiftUI

struct StallySampleData: PreviewModifier {
    typealias Context = StallyPlatformEnvironment

    static func makeSharedContext() throws -> Context {
        try StallyPlatformEnvironmentFactory.makePreview(
            seedSampleData: true
        )
    }

    func body(
        content: Content,
        context: Context
    ) -> some View {
        content.stallyPlatformEnvironment(context)
    }
}
