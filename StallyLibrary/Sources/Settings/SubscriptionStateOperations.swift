/// Resolves `SubscriptionState` from purchased products.
public enum SubscriptionStateOperations {
    /// Builds a subscription state for the given purchase set.
    public static func calculate(
        purchasedProductIDs: Set<String>,
        productID: String
    ) -> SubscriptionState {
        let isSubscribeOn = purchasedProductIDs.contains(productID)
        return .init(isSubscribeOn: isSubscribeOn)
    }
}
