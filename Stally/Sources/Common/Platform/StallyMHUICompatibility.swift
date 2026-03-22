import SwiftUI

struct StallyGlassContainer<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26, *) {
            if let spacing {
                GlassEffectContainer(spacing: spacing) {
                    content
                }
            } else {
                GlassEffectContainer {
                    content
                }
            }
        } else {
            content
        }
    }
}

extension View {
    @ViewBuilder
    func stallyGlassEffectID<Identifier: Hashable & Sendable>(
        _ identifier: Identifier,
        in namespace: Namespace.ID
    ) -> some View {
        if #available(iOS 26, *) {
            glassEffectID(identifier, in: namespace)
        } else {
            self
        }
    }
}
