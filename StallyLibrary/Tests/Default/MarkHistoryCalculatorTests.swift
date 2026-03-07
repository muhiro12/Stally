@testable import StallyLibrary
import XCTest

@MainActor
final class MarkHistoryCalculatorTests: XCTestCase {
    func testMonthsMarkCellsAcrossMonthBoundaries() throws {
        let context = testContext()
        let item = try ItemService.create(
            context: context,
            input: .init(
                name: "Pocket Notebook",
                category: .notebooks
            )
        )

        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 2, day: 28)
        )
        _ = try MarkService.mark(
            context: context,
            item: item,
            on: localDate(year: 2026, month: 3, day: 1)
        )

        let months = MarkHistoryCalculator.months(
            for: item,
            count: 2,
            referenceDate: localDate(year: 2026, month: 3, day: 12)
        )

        XCTAssertEqual(months.count, 2)

        let marchMonth = months[0]
        let februaryMonth = months[1]

        let marchOneCell = marchMonth.cells.first { cell in
            cell.isInDisplayedMonth && cell.dayNumber == 1
        }
        let februaryTwentyEightCell = februaryMonth.cells.first { cell in
            cell.isInDisplayedMonth && cell.dayNumber == 28
        }

        XCTAssertEqual(
            Calendar.current.component(.month, from: marchMonth.monthStart),
            3
        )
        XCTAssertEqual(
            Calendar.current.component(.month, from: februaryMonth.monthStart),
            2
        )
        XCTAssertTrue(marchOneCell?.isMarked == true)
        XCTAssertTrue(februaryTwentyEightCell?.isMarked == true)
    }
}
