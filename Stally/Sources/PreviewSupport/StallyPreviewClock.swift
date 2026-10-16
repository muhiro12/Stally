#if DEBUG
import Foundation

/// Advances only explicitly requested synthetic sessions across a UTC day boundary.
struct StallyPreviewClock {
    private enum Offset {
        static let beforeMidnight: TimeInterval = 43_199
        static let afterMidnight: TimeInterval = 43_201
    }

    let sendsTimeChange: Bool
    private let transition: ContinuousClock.Instant?

    var date: Date {
        guard let transition else {
            return StallyFixtureOperations.referenceDate
        }
        return StallyFixtureOperations.referenceDate.addingTimeInterval(
            ContinuousClock().now >= transition ? Offset.afterMidnight : Offset.beforeMidnight
        )
    }

    var remainingDelay: Duration? {
        transition.map { transition in
            max(.zero, ContinuousClock().now.duration(to: transition))
        }
    }

    init(advanceAfter seconds: TimeInterval?, sendsTimeChange: Bool) {
        if let seconds, seconds.isFinite, seconds > .zero, seconds <= 3_600 {
            transition = ContinuousClock().now.advanced(by: .seconds(seconds))
        } else {
            transition = nil
        }
        self.sendsTimeChange = sendsTimeChange
    }
}
#endif
