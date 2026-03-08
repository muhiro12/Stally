@testable import StallyLibrary
import SwiftData
import XCTest

@MainActor
final class ItemReviewCalculatorTests: XCTestCase {
    private struct ReviewSummaryFixture {
        let untouchedItem: Item
        let dormantItem: Item
        let healthyItem: Item
        let recoveryItem: Item
        let coldArchiveItem: Item
    }

    func testFreshUnmarkedItemStaysHealthyUntilGracePeriodExpires() throws {
        let context = testContext()
        let freshItem = try createTestItem(
            context: context,
            name: "Fresh Tee",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )
        let staleItem = try createTestItem(
            context: context,
            name: "Stale Tee",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 2, day: 20)
        )

        let snapshots = ItemReviewCalculator.snapshots(
            from: [freshItem, staleItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(
            snapshots.first { $0.itemID == freshItem.id }?.status,
            .healthy
        )
        XCTAssertEqual(
            snapshots.first { $0.itemID == staleItem.id }?.status,
            .untouched
        )
    }

    func testDormantClassificationUsesLastMarkedDate() throws {
        let context = testContext()
        let dormantItem = try createTestItem(
            context: context,
            name: "Dormant Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        let healthyItem = try createTestItem(
            context: context,
            name: "Healthy Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )

        _ = try markTestItem(
            context: context,
            item: dormantItem,
            on: localDate(year: 2_026, month: 2, day: 1)
        )
        _ = try markTestItem(
            context: context,
            item: healthyItem,
            on: localDate(year: 2_026, month: 3, day: 2)
        )

        let snapshots = ItemReviewCalculator.snapshots(
            from: [healthyItem, dormantItem],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        let dormantSnapshot = try XCTUnwrap(
            snapshots.first { $0.itemID == dormantItem.id }
        )
        let healthySnapshot = try XCTUnwrap(
            snapshots.first { $0.itemID == healthyItem.id }
        )

        XCTAssertEqual(dormantSnapshot.status, .dormant)
        XCTAssertEqual(dormantSnapshot.daysSinceLastMark, 35)
        XCTAssertEqual(healthySnapshot.status, .healthy)
    }

    func testArchivedItemsSplitBetweenRecoveryAndColdArchive() throws {
        let context = testContext()
        let recoveryItem = try createTestItem(
            context: context,
            name: "Recovery Bag",
            category: .bags
        )
        let coldArchiveItem = try createTestItem(
            context: context,
            name: "Cold Bag",
            category: .bags
        )

        _ = try markTestItem(
            context: context,
            item: recoveryItem,
            on: localDate(year: 2_026, month: 2, day: 10)
        )
        try archiveTestItem(
            context: context,
            item: recoveryItem,
            at: localDate(year: 2_026, month: 3, day: 1)
        )
        try archiveTestItem(
            context: context,
            item: coldArchiveItem,
            at: localDate(year: 2_026, month: 3, day: 1)
        )

        let recoverySnapshot = ItemReviewCalculator.snapshot(
            for: recoveryItem,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )
        let coldArchiveSnapshot = ItemReviewCalculator.snapshot(
            for: coldArchiveItem,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(recoverySnapshot.status, .recoveryCandidate)
        XCTAssertEqual(coldArchiveSnapshot.status, .coldArchive)
    }

    func testSummaryCountsAllReviewBuckets() throws {
        let context = testContext()
        let items = try makeReviewSummaryFixture(context: context)
        let summary = ItemReviewCalculator.summary(
            from: [
                items.untouchedItem,
                items.dormantItem,
                items.healthyItem,
                items.recoveryItem,
                items.coldArchiveItem
            ],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(summary.totalItems, 5)
        XCTAssertEqual(summary.untouchedCount, 1)
        XCTAssertEqual(summary.dormantCount, 1)
        XCTAssertEqual(summary.healthyCount, 1)
        XCTAssertEqual(summary.recoveryCandidateCount, 1)
        XCTAssertEqual(summary.coldArchiveCount, 1)
        XCTAssertEqual(summary.totalReviewCount, 3)
        XCTAssertEqual(summary.activeReviewCount, 2)
    }

    private func makeReviewSummaryFixture(
        context: ModelContext
    ) throws -> ReviewSummaryFixture {
        let fixture = try createReviewSummaryFixture(context: context)
        try populateReviewSummaryFixture(
            context: context,
            fixture: fixture
        )

        return fixture
    }

    private func createReviewSummaryFixture(
        context: ModelContext
    ) throws -> ReviewSummaryFixture {
        let untouchedItem = try createTestItem(
            context: context,
            name: "Untouched Notebook",
            category: .notebooks,
            createdAt: localDate(year: 2_026, month: 2, day: 15)
        )
        let dormantItem = try createTestItem(
            context: context,
            name: "Dormant Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        let healthyItem = try createTestItem(
            context: context,
            name: "Healthy Sneakers",
            category: .shoes,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        let recoveryItem = try createTestItem(
            context: context,
            name: "Recovery Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        let coldArchiveItem = try createTestItem(
            context: context,
            name: "Cold Archive Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )

        return .init(
            untouchedItem: untouchedItem,
            dormantItem: dormantItem,
            healthyItem: healthyItem,
            recoveryItem: recoveryItem,
            coldArchiveItem: coldArchiveItem
        )
    }

    private func populateReviewSummaryFixture(
        context: ModelContext,
        fixture: ReviewSummaryFixture
    ) throws {
        _ = try markTestItem(
            context: context,
            item: fixture.dormantItem,
            on: localDate(year: 2_026, month: 2, day: 1)
        )
        _ = try markTestItem(
            context: context,
            item: fixture.healthyItem,
            on: localDate(year: 2_026, month: 3, day: 4)
        )
        _ = try markTestItem(
            context: context,
            item: fixture.recoveryItem,
            on: localDate(year: 2_026, month: 2, day: 15)
        )
        try archiveTestItem(
            context: context,
            item: fixture.recoveryItem,
            at: localDate(year: 2_026, month: 3, day: 2)
        )
        try archiveTestItem(
            context: context,
            item: fixture.coldArchiveItem,
            at: localDate(year: 2_026, month: 3, day: 2)
        )
    }
}
