import Foundation
import SwiftData
@testable import Stally
@testable import StallyLibrary
import XCTest

final class StallyItemEditorModelTests: XCTestCase {
    func testCreateSavePersistsNewItem() async throws {
        try await MainActor.run {
            let context = testContext()
            let model = StallyItemEditorModel(mode: .create)

            model.name = "Daily Tote"
            model.category = .bags
            model.note = "Carry-on"

            let itemID = try model.save(context: context)
            let items = try fetchItems(context: context)

            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.id, itemID)
            XCTAssertEqual(items.first?.name, "Daily Tote")
            XCTAssertFalse(model.isSaving)
        }
    }

    func testEditSaveUpdatesExistingItem() async throws {
        try await MainActor.run {
            let context = testContext()
            let item = try createTestItem(
                context: context,
                name: "Field Camera",
                category: .bags
            )
            let model = StallyItemEditorModel(mode: .edit(item))

            model.name = "Travel Camera"
            model.note = "Mirrorless"

            _ = try model.save(context: context)

            let items = try fetchItems(context: context)
            XCTAssertEqual(items.first?.name, "Travel Camera")
            XCTAssertEqual(items.first?.note, "Mirrorless")
            XCTAssertFalse(model.isSaving)
        }
    }

    func testDeleteRemovesExistingItem() async throws {
        try await MainActor.run {
            let context = testContext()
            let item = try createTestItem(
                context: context,
                name: "Weekend Cap",
                category: .clothing
            )
            let model = StallyItemEditorModel(mode: .edit(item))

            let deletedItemID = try model.delete(context: context)

            XCTAssertEqual(deletedItemID, item.id)
            XCTAssertTrue(try fetchItems(context: context).isEmpty)
            XCTAssertFalse(model.isDeleting)
        }
    }

    func testBlankNameCannotSave() async {
        await MainActor.run {
            let model = StallyItemEditorModel(mode: .create)
            model.name = "   "

            XCTAssertFalse(model.canSave)
        }
    }

    func testPhotoLoadFailureSetsErrorMessage() async {
        let errorMessage = await Self.photoLoadFailureMessage()

        XCTAssertEqual(
            errorMessage,
            StallyLocalization.string("Failed to load the selected photo.")
        )
    }

    func testRequestDiscardConfirmationOnlyWhenChangesExist() async {
        await MainActor.run {
            let model = StallyItemEditorModel(mode: .create)

            XCTAssertTrue(model.requestDiscardConfirmationIfNeeded())
            XCTAssertFalse(model.isDiscardConfirmationPresented)

            model.name = "Umbrella"

            XCTAssertFalse(model.requestDiscardConfirmationIfNeeded())
            XCTAssertTrue(model.isDiscardConfirmationPresented)
        }
    }

    func testRequestDeleteConfirmationSetsFlag() async {
        await MainActor.run {
            let model = StallyItemEditorModel(mode: .create)

            model.requestDeleteConfirmation()

            XCTAssertTrue(model.isDeleteConfirmationPresented)
        }
    }
}

private extension StallyItemEditorModelTests {
    @MainActor
    static func photoLoadFailureMessage() async -> String? {
        let model = StallyItemEditorModel(mode: .create)

        await model.loadPhotoData {
            struct TestError: Error {}
            throw TestError()
        }

        return model.errorMessage
    }
}
