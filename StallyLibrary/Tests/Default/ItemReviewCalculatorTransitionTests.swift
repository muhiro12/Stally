@testable import StallyLibrary
import XCTest

@MainActor
final class ItemReviewCalculatorTransitionTests: XCTestCase {
    func testArchivingUntouchedItemRemovesItFromActiveReviewCounts() throws {
        let context = testContext()
        let untouchedItem = try createTestItem(
            context: context,
            name: "Quiet Notebook",
            category: .notebooks,
            createdAt: localDate(year: 2_026, month: 2, day: 15)
        )

        let beforeArchive = ItemReviewCalculator.summary(
            from: [untouchedItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        try archiveTestItem(
            context: context,
            item: untouchedItem,
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        let afterArchive = ItemReviewCalculator.summary(
            from: [untouchedItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeArchive.untouchedCount, 1)
        XCTAssertEqual(beforeArchive.totalReviewCount, 1)
        XCTAssertEqual(afterArchive.untouchedCount, 0)
        XCTAssertEqual(afterArchive.recoveryCandidateCount, 0)
        XCTAssertEqual(afterArchive.coldArchiveCount, 1)
        XCTAssertEqual(afterArchive.totalReviewCount, 0)
    }

    func testArchivingDormantItemRemovesItFromReviewCounts() throws {
        let context = testContext()
        let dormantItem = try createTestItem(
            context: context,
            name: "Sleepy Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )

        _ = try markTestItem(
            context: context,
            item: dormantItem,
            on: localDate(year: 2_026, month: 2, day: 1)
        )

        let beforeArchive = ItemReviewCalculator.summary(
            from: [dormantItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        try archiveTestItem(
            context: context,
            item: dormantItem,
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        let afterArchive = ItemReviewCalculator.summary(
            from: [dormantItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeArchive.dormantCount, 1)
        XCTAssertEqual(beforeArchive.totalReviewCount, 1)
        XCTAssertEqual(afterArchive.dormantCount, 0)
        XCTAssertEqual(afterArchive.recoveryCandidateCount, 1)
        XCTAssertEqual(afterArchive.totalReviewCount, 1)
    }

    func testUnarchivingRecoveryItemCanMakeItHealthyAgain() throws {
        let context = testContext()
        let recoveryItem = try createTestItem(
            context: context,
            name: "Recovered Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )

        _ = try markTestItem(
            context: context,
            item: recoveryItem,
            on: localDate(year: 2_026, month: 3, day: 5)
        )
        try archiveTestItem(
            context: context,
            item: recoveryItem,
            at: localDate(year: 2_026, month: 3, day: 6)
        )

        let beforeUnarchive = ItemReviewCalculator.summary(
            from: [recoveryItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        try unarchiveTestItem(
            context: context,
            item: recoveryItem,
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        let afterUnarchive = ItemReviewCalculator.summary(
            from: [recoveryItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeUnarchive.recoveryCandidateCount, 1)
        XCTAssertEqual(beforeUnarchive.totalReviewCount, 1)
        XCTAssertEqual(afterUnarchive.recoveryCandidateCount, 0)
        XCTAssertEqual(afterUnarchive.healthyCount, 1)
        XCTAssertEqual(afterUnarchive.totalReviewCount, 0)
    }
}
