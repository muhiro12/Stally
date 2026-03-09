import SwiftUI

struct StallySampleData: PreviewModifier {
    typealias Context = StallyAppAssembly

    static func makeSharedContext() throws -> Context {
        try StallyAppAssemblyFactory.makePreview(
            seedSampleData: true
        )
    }

    func body(
        content: Content,
        context: Context
    ) -> some View {
        content.stallyAppAssembly(context)
    }
}
