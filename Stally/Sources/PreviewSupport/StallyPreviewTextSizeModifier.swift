#if DEBUG
import SwiftUI

/// Overrides only an explicitly requested synthetic review environment.
struct StallyPreviewTextSizeModifier: ViewModifier {
    let size: DynamicTypeSize?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let size {
            content.environment(\.dynamicTypeSize, size)
        } else {
            content
        }
    }
}
#endif
