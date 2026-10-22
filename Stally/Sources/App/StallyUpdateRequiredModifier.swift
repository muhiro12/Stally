import MHPlatform
import SwiftUI

struct StallyUpdateRequiredModifier: ViewModifier {
    @Environment(RemoteUpdateOperations.self)
    private var remoteUpdates

    private var isRequired: Bool {
        remoteUpdates.decision == .updateRequired
    }

    func body(content: Content) -> some View {
        content
            .disabled(isRequired)
            .accessibilityHidden(isRequired)
            .overlay {
                if isRequired {
                    StallyUpdateRequiredView()
                        .environment(\.isEnabled, true)
                        .accessibilityHidden(false)
                }
            }
            .interactiveDismissDisabled(isRequired)
    }
}
