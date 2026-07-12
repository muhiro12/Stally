//
//  ItemValidationError.swift
//  StallyLibrary
//
//  Created by Hiromu Nakano on 2026/06/26.
//

import Foundation

/// Validation failures for item input.
public enum ItemValidationError: Equatable, LocalizedError, Sendable {
    case archivedItemsCannotChangeHistory
    case futureMarksNotAllowed
    case nameRequired

    /// User-readable validation message.
    public var errorDescription: String? {
        switch self {
        case .archivedItemsCannotChangeHistory:
            String(
                localized: "Move this item back to Library before changing its history.",
                bundle: #bundle
            )
        case .futureMarksNotAllowed:
            String(localized: "Marks cannot be added for a future day.", bundle: #bundle)
        case .nameRequired:
            String(localized: "Item name is required.", bundle: #bundle)
        }
    }
}
