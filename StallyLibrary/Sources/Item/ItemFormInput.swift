//
//  ItemFormInput.swift
//  StallyLibrary
//
//  Created by Hiromu Nakano on 2026/06/26.
//

import Foundation

/// User-editable values for creating or updating a Library item.
public struct ItemFormInput: Equatable, Sendable {
    /// User-facing item name.
    public let name: String
    /// Product category selected for the item.
    public let category: ItemCategory
    /// Optional note that gives the item more context.
    public let note: String
    /// Optional source image data normalized when the item is created or updated.
    public let photoData: Data?

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Creates item form input from editable values.
    public init(
        name: String,
        category: ItemCategory,
        note: String = "",
        photoData: Data? = nil
    ) {
        self.name = name
        self.category = category
        self.note = note
        self.photoData = photoData
    }
}
