#if DEBUG
import SwiftUI

/// Synthetic launches share the fixture clock without changing system settings.
struct StallyPreviewTimeZoneModifier: ViewModifier {
    @Environment(\.timeZone)
    private var timeZone

    let referenceDate: Date?

    func body(content: Content) -> some View {
        content.environment(
            \.timeZone,
            referenceDate == nil ? timeZone : StallyFixtureOperations.timeZone
        )
    }
}
#endif
