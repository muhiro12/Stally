@testable import StallyLibrary
import Testing

struct SubscriptionStateOperationsTests {
    @Test
    func calculate_is_inactive_when_product_is_not_purchased() {
        let state = SubscriptionStateOperations.calculate(
            purchasedProductIDs: ["other.product"],
            productID: "com.example.product"
        )

        #expect(state.isSubscribeOn == false)
    }

    @Test
    func calculate_is_active_when_product_is_purchased() {
        let state = SubscriptionStateOperations.calculate(
            purchasedProductIDs: ["com.example.product"],
            productID: "com.example.product"
        )

        #expect(state.isSubscribeOn == true)
    }

    @Test
    func calculate_is_inactive_when_purchase_set_is_empty() {
        let state = SubscriptionStateOperations.calculate(
            purchasedProductIDs: [],
            productID: "com.example.product"
        )

        #expect(state.isSubscribeOn == false)
    }
}
