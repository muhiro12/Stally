import Foundation

/// Create/edit payload for a Stally item.
public struct ItemFormInput: Equatable, Sendable {
    /// Validation failures surfaced by the form flow.
    public enum ValidationError: LocalizedError, Equatable {
        case emptyName

        public var errorDescription: String? {
            switch self {
            case .emptyName:
                StallyLibraryLocalization.string("Name is required.")
            }
        }
    }

    public let name: String
    public let category: ItemCategory
    public let photoData: Data?
    public let note: String?

    public init(
        name: String,
        category: ItemCategory = .other,
        photoData: Data? = nil,
        note: String? = nil
    ) {
        self.name = name
        self.category = category
        self.photoData = photoData
        self.note = note
    }

    /// Returns a normalized input trimmed for persistence.
    public func normalized() -> Self {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNote = trimmedNote?.isEmpty == false ? trimmedNote : nil
        let normalizedPhotoData = photoData?.isEmpty == false ? photoData : nil

        return .init(
            name: trimmedName,
            category: category,
            photoData: normalizedPhotoData,
            note: normalizedNote
        )
    }

    /// Returns a validated, normalized input suitable for persistence.
    public func validated() throws -> Self {
        let normalizedInput = normalized()

        guard !normalizedInput.name.isEmpty else {
            throw ValidationError.emptyName
        }

        return normalizedInput
    }
}
