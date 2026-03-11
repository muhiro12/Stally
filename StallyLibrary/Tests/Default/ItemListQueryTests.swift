@testable import StallyLibrary
import XCTest

final class ItemListQueryTests: XCTestCase {
    func testTrimmedSearchTextDropsSurroundingWhitespace() {
        let query = ItemListQuery(
            searchText: "  office tote  "
        )

        XCTAssertEqual(query.trimmedSearchText, "office tote")
    }

    func testHasRefinementsIsFalseForDefaultQuery() {
        let query = ItemListQuery()

        XCTAssertFalse(query.hasRefinements)
    }

    func testHasRefinementsBecomesTrueForEachNonDefaultField() {
        XCTAssertTrue(
            ItemListQuery(
                searchText: " notebook "
            ).hasRefinements
        )
        XCTAssertTrue(
            ItemListQuery(
                category: .bags
            ).hasRefinements
        )
        XCTAssertTrue(
            ItemListQuery(
                quickFilter: .withHistory
            ).hasRefinements
        )
        XCTAssertTrue(
            ItemListQuery(
                sortOption: .mostMarked
            ).hasRefinements
        )
    }
}
