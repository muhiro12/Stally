//
//  ItemValidationError.swift
//  StallyLibrary
//
//  Created by Hiromu Nakano on 2026/06/26.
//

import Foundation

/// Validation failures for item input.
public enum ItemValidationError: Equatable, LocalizedError, Sendable {
    case nameRequired

    /// User-readable validation message.
    public var errorDescription: String? {
        switch self {
        case .nameRequired:
            "Item name is required."
        }
    }
}
