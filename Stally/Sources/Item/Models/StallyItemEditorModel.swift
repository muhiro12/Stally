import Foundation
import Observation
import StallyLibrary
import SwiftData

@MainActor
@Observable
final class StallyItemEditorModel {
    enum Mode {
        case create
        case edit(Item)
    }

    private struct DraftState: Equatable {
        let name: String
        let category: ItemCategory
        let note: String
        let photoData: Data?
    }

    private let originalState: DraftState

    let mode: Mode

    var name: String
    var category: ItemCategory
    var note: String
    var photoData: Data?
    var errorMessage: String?
    var isDeleteConfirmationPresented = false
    var isDiscardConfirmationPresented = false
    var isSaving = false
    var isDeleting = false

    init(
        mode: Mode
    ) {
        self.mode = mode

        let initialName: String
        let initialCategory: ItemCategory
        let initialNote: String
        let initialPhotoData: Data?

        switch mode {
        case .create:
            initialName = ""
            initialCategory = .other
            initialNote = ""
            initialPhotoData = nil
        case .edit(let item):
            initialName = item.name
            initialCategory = item.category
            initialNote = item.note ?? ""
            initialPhotoData = item.photoData
        }

        self.name = initialName
        self.category = initialCategory
        self.note = initialNote
        self.photoData = initialPhotoData

        self.originalState = .init(
            name: initialName,
            category: initialCategory,
            note: initialNote,
            photoData: initialPhotoData
        )
    }

    var existingItem: Item? {
        switch mode {
        case .create:
            nil
        case .edit(let item):
            item
        }
    }

    var navigationTitle: String {
        switch mode {
        case .create:
            StallyLocalization.string("Add Item")
        case .edit:
            StallyLocalization.string("Edit Item")
        }
    }

    var screenSubtitle: String {
        switch mode {
        case .create:
            StallyLocalization.string(
                "Create an item you can mark once when you chose it today."
            )
        case .edit:
            StallyLocalization.string(
                "Adjust the basics without changing the marks you already kept."
            )
        }
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty
    }

    var hasChanges: Bool {
        currentState != originalState
    }

    var photoButtonTitle: String {
        photoData == nil
            ? StallyLocalization.string("Choose Photo")
            : StallyLocalization.string("Replace Photo")
    }

    private var currentState: DraftState {
        .init(
            name: name,
            category: category,
            note: note,
            photoData: photoData
        )
    }

    var formInput: ItemFormInput {
        .init(
            name: name,
            category: category,
            photoData: photoData,
            note: note
        )
    }

    func loadPhotoData(
        using loader: () async throws -> Data?
    ) async {
        do {
            photoData = try await loader()
        } catch {
            errorMessage = StallyLocalization.string(
                "Failed to load the selected photo."
            )
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    func requestDeleteConfirmation() {
        isDeleteConfirmationPresented = true
    }

    func requestDiscardConfirmationIfNeeded() -> Bool {
        guard hasChanges else {
            return true
        }

        isDiscardConfirmationPresented = true
        return false
    }

    func dismissDiscardConfirmation() {
        isDiscardConfirmationPresented = false
    }

    func dismissDeleteConfirmation() {
        isDeleteConfirmationPresented = false
    }

    func presentSaveError(
        _ error: any Error
    ) {
        errorMessage = (error as? LocalizedError)?.errorDescription
            ?? StallyLocalization.string("Failed to save this item.")
    }

    func presentDeleteError(
        _ error: any Error
    ) {
        errorMessage = (error as? LocalizedError)?.errorDescription
            ?? StallyLocalization.string("Failed to delete this item.")
    }

    func removePhoto() {
        photoData = nil
    }

    func save(
        context: ModelContext
    ) throws -> UUID {
        isSaving = true
        defer {
            isSaving = false
        }

        switch mode {
        case .create:
            return try ItemService.create(
                context: context,
                input: formInput
            ).id
        case .edit(let item):
            try ItemService.update(
                context: context,
                item: item,
                input: formInput
            )
            return item.id
        }
    }

    func delete(
        context: ModelContext
    ) throws -> UUID {
        isDeleting = true
        defer {
            isDeleting = false
        }

        guard let existingItem else {
            throw ItemFormInput.ValidationError.emptyName
        }

        try ItemService.delete(
            context: context,
            item: existingItem
        )

        return existingItem.id
    }
}
