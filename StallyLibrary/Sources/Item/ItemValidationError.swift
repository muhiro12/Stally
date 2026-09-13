//
//  ItemValidationError.swift
//  StallyLibrary
//
//  Created by Hiromu Nakano on 2026/06/26.
//

import Foundation

/// Validation failures for item input.
public enum ItemValidationError: Equatable, LocalizedError, CustomLocalizedStringResourceConvertible, Sendable {
    case archivedItemsCannotChangeHistory
    case futureMarksNotAllowed
    case nameRequired
    case photoTooLarge
    case photoUnreadable
    case invalidStart
    case futureStartNotAllowed
    case marksNotEnabled
    case existingMarksRequireRecording

    /// User-readable validation message.
    public var errorDescription: String? {
        String(localized: localizedStringResource)
    }

    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .archivedItemsCannotChangeHistory:
            .init(
                "Move this item back to Library before changing its history.",
                bundle: #bundle
            )
        case .futureMarksNotAllowed:
            .init( "Marks cannot be added for a future day.", bundle: #bundle)
        case .nameRequired:
            .init( "Item name is required.", bundle: #bundle)
        case .photoTooLarge:
            .init( "The selected photo is too large.", bundle: #bundle)
        case .photoUnreadable:
            .init( "The selected photo could not be read.", bundle: #bundle)
        case .invalidStart:
            .init( "The stored start is invalid. Edit or clear it before saving.", bundle: #bundle)
        case .futureStartNotAllowed:
            .init( "Choose a start no later than today.", bundle: #bundle)
        case .marksNotEnabled:
            .init( "This item does not record Marks.", bundle: #bundle)
        case .existingMarksRequireRecording:
            .init( "Keep Marks enabled to preserve this item's existing history.", bundle: #bundle)
        }
    }
}
