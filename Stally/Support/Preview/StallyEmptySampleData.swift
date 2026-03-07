import MHUI
import MHPlatform
import StallyLibrary
import SwiftData
import SwiftUI

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
            .tint(StallyDesign.tint)
            .mhTheme(MHTheme.standard())
            .environment(context.appRuntime)
            .environment(context.deepLinkInbox)
    }
}
