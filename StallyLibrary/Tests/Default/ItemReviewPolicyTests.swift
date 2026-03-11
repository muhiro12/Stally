@testable import StallyLibrary
import XCTest

final class ItemReviewPolicyTests: XCTestCase {
    func testInitClampsThresholdsToAtLeastOneDay() {
        let policy = ItemReviewPolicy(
            untouchedGraceDays: 0,
            dormantAfterDays: -7
        )

        XCTAssertEqual(policy.untouchedGraceDays, 1)
        XCTAssertEqual(policy.dormantAfterDays, 1)
    }

    func testInitKeepsExplicitPositiveThresholds() {
        let policy = ItemReviewPolicy(
            untouchedGraceDays: 21,
            dormantAfterDays: 45
        )

        XCTAssertEqual(policy.untouchedGraceDays, 21)
        XCTAssertEqual(policy.dormantAfterDays, 45)
    }
}
