@testable import StallyLibrary
import XCTest

@MainActor
final class ItemReviewCalculatorTests: XCTestCase {
    func testFreshUnmarkedItemStaysHealthyUntilGracePeriodExpires() throws {
        let context = testContext()
        let freshItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Fresh Tee",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 3, day: 1)
        )
        let staleItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Stale Tee",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 2, day: 20)
        )

        let snapshots = ItemReviewCalculator.snapshots(
            from: [freshItem, staleItem],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
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
        let dormantItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Dormant Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )
        let healthyItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Healthy Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )

        _ = try MarkService.mark(
            context: context,
            item: dormantItem,
            on: localDate(year: 2026, month: 2, day: 1)
        )
        _ = try MarkService.mark(
            context: context,
            item: healthyItem,
            on: localDate(year: 2026, month: 3, day: 2)
        )

        let snapshots = ItemReviewCalculator.snapshots(
            from: [healthyItem, dormantItem],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
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
        let recoveryItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Recovery Bag",
                category: .bags
            )
        )
        let coldArchiveItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Cold Bag",
                category: .bags
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: recoveryItem,
            on: localDate(year: 2026, month: 2, day: 10)
        )
        try ItemService.archive(
            context: context,
            item: recoveryItem,
            at: localDate(year: 2026, month: 3, day: 1)
        )
        try ItemService.archive(
            context: context,
            item: coldArchiveItem,
            at: localDate(year: 2026, month: 3, day: 1)
        )

        let recoverySnapshot = ItemReviewCalculator.snapshot(
            for: recoveryItem,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )
        let coldArchiveSnapshot = ItemReviewCalculator.snapshot(
            for: coldArchiveItem,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(recoverySnapshot.status, .recoveryCandidate)
        XCTAssertEqual(coldArchiveSnapshot.status, .coldArchive)
    }

    func testSummaryCountsAllReviewBuckets() throws {
        let context = testContext()
        let untouchedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Untouched Notebook",
                category: .notebooks
            ),
            createdAt: localDate(year: 2026, month: 2, day: 15)
        )
        let dormantItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Dormant Tote",
                category: .bags
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )
        let healthyItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Healthy Sneakers",
                category: .shoes
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )
        let recoveryItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Recovery Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )
        let coldArchiveItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Cold Archive Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )

        _ = try MarkService.mark(
            context: context,
            item: dormantItem,
            on: localDate(year: 2026, month: 2, day: 1)
        )
        _ = try MarkService.mark(
            context: context,
            item: healthyItem,
            on: localDate(year: 2026, month: 3, day: 4)
        )
        _ = try MarkService.mark(
            context: context,
            item: recoveryItem,
            on: localDate(year: 2026, month: 2, day: 15)
        )
        try ItemService.archive(
            context: context,
            item: recoveryItem,
            at: localDate(year: 2026, month: 3, day: 2)
        )
        try ItemService.archive(
            context: context,
            item: coldArchiveItem,
            at: localDate(year: 2026, month: 3, day: 2)
        )

        let summary = ItemReviewCalculator.summary(
            from: [
                untouchedItem,
                dormantItem,
                healthyItem,
                recoveryItem,
                coldArchiveItem
            ],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
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
}
