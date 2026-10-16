#if DEBUG
import SwiftUI
import UIKit

/// Exercises the normal notification observer without changing any system clock.
struct StallyPreviewClockRefreshModifier: ViewModifier {
    let clock: StallyPreviewClock?

    func body(content: Content) -> some View {
        content.task {
            guard let clock, clock.sendsTimeChange, let delay = clock.remainingDelay else {
                return
            }
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            NotificationCenter.default.post(
                name: UIApplication.significantTimeChangeNotification,
                object: nil
            )
        }
    }
}
#endif
