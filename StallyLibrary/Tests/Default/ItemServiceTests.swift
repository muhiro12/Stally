import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
final class ItemServiceTests: XCTestCase {
    private struct BulkArchiveFixture {
        let untouchedItem: Item
        let markedItem: Item
        let existingArchive: Item
        let initialArchiveDate: Date

        var items: [Item] {
            [untouchedItem, markedItem, existingArchive]
        }
    }

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
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        let firstItemCount = try context.fetchCount(FetchDescriptor<Item>())
        let firstMarkCount = try context.fetchCount(FetchDescriptor<Mark>())

        try ItemService.seedSampleData(
            context: context,
            ifEmptyOnly: true,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
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
        let fixture = try makeBulkArchiveFixture(context: context)

        let beforeSummary = ItemReviewCalculator.summary(
            from: fixture.items,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        try archiveTestItems(
            context: context,
            items: [
                fixture.untouchedItem,
                fixture.markedItem,
                fixture.existingArchive,
                fixture.markedItem
            ],
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        let afterSummary = ItemReviewCalculator.summary(
            from: fixture.items,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeSummary.totalReviewCount, 1)
        XCTAssertEqual(beforeSummary.untouchedCount, 1)
        XCTAssertEqual(afterSummary.totalReviewCount, 1)
        XCTAssertEqual(afterSummary.untouchedCount, 0)
        XCTAssertEqual(afterSummary.recoveryCandidateCount, 1)
        XCTAssertEqual(afterSummary.coldArchiveCount, 2)
        XCTAssertEqual(
            ItemInsightsCalculator.summary(for: fixture.markedItem).totalMarks,
            1
        )
        XCTAssertEqual(fixture.existingArchive.archivedAt, fixture.initialArchiveDate)
        XCTAssertEqual(
            fixture.markedItem.archivedAt,
            localDate(year: 2_026, month: 3, day: 8)
        )
    }

    func testBulkArchiveMovesDormantItemsIntoRecoveryCandidates() throws {
        let context = testContext()
        let dormantCoat = try createTestItem(
            context: context,
            name: "Dormant Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        let dormantTote = try createTestItem(
            context: context,
            name: "Dormant Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )

        _ = try markTestItem(
            context: context,
            item: dormantCoat,
            on: localDate(year: 2_026, month: 2, day: 1)
        )
        _ = try markTestItem(
            context: context,
            item: dormantTote,
            on: localDate(year: 2_026, month: 2, day: 2)
        )

        let beforeSummary = ItemReviewCalculator.summary(
            from: [dormantCoat, dormantTote],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        try archiveTestItems(
            context: context,
            items: [dormantCoat, dormantTote],
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        let afterSummary = ItemReviewCalculator.summary(
            from: [dormantCoat, dormantTote],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeSummary.dormantCount, 2)
        XCTAssertEqual(beforeSummary.recoveryCandidateCount, 0)
        XCTAssertEqual(afterSummary.dormantCount, 0)
        XCTAssertEqual(afterSummary.recoveryCandidateCount, 2)
        XCTAssertEqual(afterSummary.totalReviewCount, 2)
    }

    func testBulkUnarchiveMovesRecoveryItemsBackToHealthyItems() throws {
        let context = testContext()
        let recoveryCoat = try createTestItem(
            context: context,
            name: "Recovery Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        let recoveryTote = try createTestItem(
            context: context,
            name: "Recovery Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )

        _ = try markTestItem(
            context: context,
            item: recoveryCoat,
            on: localDate(year: 2_026, month: 3, day: 5)
        )
        _ = try markTestItem(
            context: context,
            item: recoveryTote,
            on: localDate(year: 2_026, month: 3, day: 6)
        )
        try archiveTestItems(
            context: context,
            items: [recoveryCoat, recoveryTote],
            at: localDate(year: 2_026, month: 3, day: 7)
        )

        let beforeSummary = ItemReviewCalculator.summary(
            from: [recoveryCoat, recoveryTote],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        try unarchiveTestItems(
            context: context,
            items: [recoveryCoat, recoveryTote],
            at: localDate(year: 2_026, month: 3, day: 8)
        )

        let afterSummary = ItemReviewCalculator.summary(
            from: [recoveryCoat, recoveryTote],
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(beforeSummary.recoveryCandidateCount, 2)
        XCTAssertEqual(beforeSummary.totalReviewCount, 2)
        XCTAssertEqual(afterSummary.recoveryCandidateCount, 0)
        XCTAssertEqual(afterSummary.healthyCount, 2)
        XCTAssertEqual(afterSummary.totalReviewCount, 0)
    }

    private func makeBulkArchiveFixture(
        context: ModelContext
    ) throws -> BulkArchiveFixture {
        let untouchedItem = try createTestItem(
            context: context,
            name: "Quiet Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 2, day: 15)
        )
        let markedItem = try createTestItem(
            context: context,
            name: "Active Coat",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 15)
        )
        let existingArchive = try createTestItem(
            context: context,
            name: "Stored Weekender",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 1, day: 10)
        )
        let initialArchiveDate = localDate(year: 2_026, month: 3, day: 1)

        _ = try markTestItem(
            context: context,
            item: markedItem,
            on: localDate(year: 2_026, month: 3, day: 5)
        )
        try archiveTestItem(
            context: context,
            item: existingArchive,
            at: initialArchiveDate
        )

        return .init(
            untouchedItem: untouchedItem,
            markedItem: markedItem,
            existingArchive: existingArchive,
            initialArchiveDate: initialArchiveDate
        )
    }
}
