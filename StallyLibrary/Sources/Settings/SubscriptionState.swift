/// Subscription availability state for ad-free features.
public struct SubscriptionState: Sendable, Equatable {
    /// True when the ad-removal product is currently purchased.
    public let isSubscribeOn: Bool

    /// Creates a subscription state snapshot.
    public init(isSubscribeOn: Bool) {
        self.isSubscribeOn = isSubscribeOn
    }
}
