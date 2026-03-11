@testable import StallyLibrary
import XCTest

@MainActor
final class ItemInsightsRecommendationTests: XCTestCase {
    func testRecommendationsSuggestStartingWhenRangeHasNoMarks() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Black Tee",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )

        let recommendations = ItemInsightsCalculator.recommendations(
            from: [item],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertEqual(recommendations.first?.kind, .startTracking)
        XCTAssertEqual(recommendations.first?.itemIDs, [item.id])
    }

    func testRecommendationsSuggestQuietItemsAndMissingNotes() throws {
        let context = testContext()
        let quietItem = try createTestItem(
            context: context,
            name: "Quiet Tote",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        let frequentItem = try createTestItem(
            context: context,
            name: "Frequent Tee",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )

        _ = try markTestItem(
            context: context,
            item: quietItem,
            on: localDate(year: 2_026, month: 1, day: 10)
        )
        _ = try markTestItem(
            context: context,
            item: frequentItem,
            on: localDate(year: 2_026, month: 3, day: 5)
        )
        _ = try markTestItem(
            context: context,
            item: frequentItem,
            on: localDate(year: 2_026, month: 3, day: 8)
        )

        let recommendations = ItemInsightsCalculator.recommendations(
            from: [quietItem, frequentItem],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertTrue(
            recommendations.contains { recommendation in
                recommendation.kind == .revisitQuietItems
                    && recommendation.itemIDs.contains(quietItem.id)
            }
        )
        XCTAssertTrue(
            recommendations.contains { recommendation in
                recommendation.kind == .addContext
                    && recommendation.itemIDs.contains(frequentItem.id)
            }
        )
    }

    func testRecommendationsKeepHistoricalQuietItemsAheadOfUntouchedItems() throws {
        let context = testContext()
        let quietItem = try createTestItem(
            context: context,
            name: "Archived Favorite",
            category: .bags,
            createdAt: localDate(year: 2_026, month: 1, day: 1)
        )
        let untouchedItemOne = try createTestItem(
            context: context,
            name: "Fresh Tee",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )
        let untouchedItemTwo = try createTestItem(
            context: context,
            name: "Fresh Cap",
            category: .other,
            createdAt: localDate(year: 2_026, month: 3, day: 2)
        )
        let untouchedItemThree = try createTestItem(
            context: context,
            name: "Fresh Notebook",
            category: .notebooks,
            createdAt: localDate(year: 2_026, month: 3, day: 3)
        )

        _ = try markTestItem(
            context: context,
            item: quietItem,
            on: localDate(year: 2_026, month: 1, day: 10)
        )

        let recommendations = ItemInsightsCalculator.recommendations(
            from: [
                untouchedItemOne,
                untouchedItemTwo,
                untouchedItemThree,
                quietItem
            ],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertTrue(
            recommendations.contains { recommendation in
                recommendation.kind == .revisitQuietItems
                    && recommendation.itemIDs.contains(quietItem.id)
            }
        )
    }

    func testRecommendationsSuggestProtectingAnActiveStreak() throws {
        let context = testContext()
        let item = try createTestItem(
            context: context,
            name: "Streak Tee",
            category: .clothing,
            createdAt: localDate(year: 2_026, month: 3, day: 1)
        )

        for day in [6, 7, 8] {
            _ = try markTestItem(
                context: context,
                item: item,
                on: localDate(year: 2_026, month: 3, day: day)
            )
        }

        let recommendations = ItemInsightsCalculator.recommendations(
            from: [item],
            range: .last30Days,
            referenceDate: localDate(year: 2_026, month: 3, day: 8)
        )

        XCTAssertTrue(
            recommendations.contains { recommendation in
                recommendation.kind == .protectStreak
                    && recommendation.itemIDs == [item.id]
            }
        )
    }
}
