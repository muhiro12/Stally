import MHPlatform
import SwiftUI

struct StallyEmptySampleData: PreviewModifier {
    typealias Context = StallyAppAssembly

    static func makeSharedContext() throws -> Context {
        try StallyAppAssemblyFactory.makePreview(
            seedSampleData: false
        )
    }

    func body(
        content: Content,
        context: Context
    ) -> some View {
        content
            .stallyAppAssembly(context)
            .mhAppRuntimeEnvironment(context.bootstrap)
    }
}
