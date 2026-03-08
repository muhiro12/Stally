import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
final class ItemServiceTests: XCTestCase {
    func testCreateNormalizesInputBeforeSaving() throws {
        let context = testContext()

        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "  Indigo Shirt  ",
                category: .clothing,
                photoData: Data(),
                note: "  Favorite fit  "
            )
        )

        XCTAssertEqual(item.name, "Indigo Shirt")
        XCTAssertEqual(item.note, "Favorite fit")
        XCTAssertNil(item.photoData)
    }

    func testSeedSampleDataDoesNotDuplicateWhenIfEmptyOnlyIsTrue() throws {
        let context = testContext()

        try ItemService.seedSampleData(
            context: context,
            ifEmptyOnly: true,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        let firstItemCount = try context.fetchCount(FetchDescriptor<Item>())
        let firstMarkCount = try context.fetchCount(FetchDescriptor<Mark>())

        try ItemService.seedSampleData(
            context: context,
            ifEmptyOnly: true,
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Item>()),
            firstItemCount
        )
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Mark>()),
            firstMarkCount
        )
        XCTAssertGreaterThan(firstItemCount, 0)
        XCTAssertGreaterThan(firstMarkCount, 0)
    }

    func testBulkArchiveArchivesOnlyActiveItemsAndPreservesMarks() throws {
        let context = testContext()
        let untouchedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Quiet Tote",
                category: .bags
            ),
            createdAt: localDate(year: 2026, month: 2, day: 15)
        )
        let markedItem = try ItemService.create(
            context: context,
            input: .init(
                name: "Active Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 1, day: 15)
        )
        let existingArchive = try ItemService.create(
            context: context,
            input: .init(
                name: "Stored Weekender",
                category: .bags
            ),
            createdAt: localDate(year: 2026, month: 1, day: 10)
        )
        let initialArchiveDate = localDate(year: 2026, month: 3, day: 1)

        _ = try MarkService.mark(
            context: context,
            item: markedItem,
            on: localDate(year: 2026, month: 3, day: 5)
        )
        try ItemService.archive(
            context: context,
            item: existingArchive,
            at: initialArchiveDate
        )

        let beforeSummary = ItemReviewCalculator.summary(
            from: [untouchedItem, markedItem, existingArchive],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        try ItemService.archive(
            context: context,
            items: [untouchedItem, markedItem, existingArchive, markedItem],
            at: localDate(year: 2026, month: 3, day: 8)
        )

        let afterSummary = ItemReviewCalculator.summary(
            from: [untouchedItem, markedItem, existingArchive],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeSummary.totalReviewCount, 1)
        XCTAssertEqual(beforeSummary.untouchedCount, 1)
        XCTAssertEqual(afterSummary.totalReviewCount, 1)
        XCTAssertEqual(afterSummary.untouchedCount, 0)
        XCTAssertEqual(afterSummary.recoveryCandidateCount, 1)
        XCTAssertEqual(afterSummary.coldArchiveCount, 2)
        XCTAssertEqual(ItemInsightsCalculator.summary(for: markedItem).totalMarks, 1)
        XCTAssertEqual(existingArchive.archivedAt, initialArchiveDate)
        XCTAssertEqual(markedItem.archivedAt, localDate(year: 2026, month: 3, day: 8))
    }

    func testBulkArchiveMovesDormantItemsIntoRecoveryCandidates() throws {
        let context = testContext()
        let dormantCoat = try ItemService.create(
            context: context,
            input: .init(
                name: "Dormant Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )
        let dormantTote = try ItemService.create(
            context: context,
            input: .init(
                name: "Dormant Tote",
                category: .bags
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )

        _ = try MarkService.mark(
            context: context,
            item: dormantCoat,
            on: localDate(year: 2026, month: 2, day: 1)
        )
        _ = try MarkService.mark(
            context: context,
            item: dormantTote,
            on: localDate(year: 2026, month: 2, day: 2)
        )

        let beforeSummary = ItemReviewCalculator.summary(
            from: [dormantCoat, dormantTote],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        try ItemService.archive(
            context: context,
            items: [dormantCoat, dormantTote],
            at: localDate(year: 2026, month: 3, day: 8)
        )

        let afterSummary = ItemReviewCalculator.summary(
            from: [dormantCoat, dormantTote],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeSummary.dormantCount, 2)
        XCTAssertEqual(beforeSummary.recoveryCandidateCount, 0)
        XCTAssertEqual(afterSummary.dormantCount, 0)
        XCTAssertEqual(afterSummary.recoveryCandidateCount, 2)
        XCTAssertEqual(afterSummary.totalReviewCount, 2)
    }

    func testBulkUnarchiveMovesRecoveryItemsBackToHealthyItems() throws {
        let context = testContext()
        let recoveryCoat = try ItemService.create(
            context: context,
            input: .init(
                name: "Recovery Coat",
                category: .clothing
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )
        let recoveryTote = try ItemService.create(
            context: context,
            input: .init(
                name: "Recovery Tote",
                category: .bags
            ),
            createdAt: localDate(year: 2026, month: 1, day: 1)
        )

        _ = try MarkService.mark(
            context: context,
            item: recoveryCoat,
            on: localDate(year: 2026, month: 3, day: 5)
        )
        _ = try MarkService.mark(
            context: context,
            item: recoveryTote,
            on: localDate(year: 2026, month: 3, day: 6)
        )
        try ItemService.archive(
            context: context,
            items: [recoveryCoat, recoveryTote],
            at: localDate(year: 2026, month: 3, day: 7)
        )

        let beforeSummary = ItemReviewCalculator.summary(
            from: [recoveryCoat, recoveryTote],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        try ItemService.unarchive(
            context: context,
            items: [recoveryCoat, recoveryTote],
            at: localDate(year: 2026, month: 3, day: 8)
        )

        let afterSummary = ItemReviewCalculator.summary(
            from: [recoveryCoat, recoveryTote],
            referenceDate: localDate(year: 2026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeSummary.recoveryCandidateCount, 2)
        XCTAssertEqual(beforeSummary.totalReviewCount, 2)
        XCTAssertEqual(afterSummary.recoveryCandidateCount, 0)
        XCTAssertEqual(afterSummary.healthyCount, 2)
        XCTAssertEqual(afterSummary.totalReviewCount, 0)
    }
}
