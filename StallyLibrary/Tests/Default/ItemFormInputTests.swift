@testable import StallyLibrary
import XCTest

final class ItemFormInputTests: XCTestCase {
    func testNormalizedTrimsNameDropsBlankNoteAndEmptyPhoto() {
        let input = ItemFormInput(
            name: "  Daily Tote  ",
            category: .bags,
            photoData: Data(),
            note: "   "
        )

        let normalized = input.normalized()

        XCTAssertEqual(normalized.name, "Daily Tote")
        XCTAssertEqual(normalized.category, .bags)
        XCTAssertNil(normalized.note)
        XCTAssertNil(normalized.photoData)
    }

    func testValidatedRejectsEmptyTrimmedName() {
        let input = ItemFormInput(
            name: "  \n  ",
            category: .other
        )

        XCTAssertThrowsError(
            try input.validated()
        ) { error in
            XCTAssertEqual(
                error as? ItemFormInput.ValidationError,
                .emptyName
            )
        }
    }

    func testValidatedPreservesMeaningfulNoteAndPhoto() throws {
        let photoData = Data([1, 2, 3])
        let input = ItemFormInput(
            name: "Notebook",
            category: .notebooks,
            photoData: photoData,
            note: "  Capture field notes  "
        )

        let validated = try input.validated()

        XCTAssertEqual(validated.name, "Notebook")
        XCTAssertEqual(validated.category, .notebooks)
        XCTAssertEqual(validated.photoData, photoData)
        XCTAssertEqual(validated.note, "Capture field notes")
    }
}
