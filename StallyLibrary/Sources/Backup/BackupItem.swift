//
//  BackupItem.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Portable item payload stored in a Stally backup.
public struct BackupItem: Codable, Equatable, Identifiable, Sendable {
    /// Stable item identifier.
    public let id: UUID
    /// User-facing item name.
    public let name: String
    /// Raw category label.
    public let categoryRawValue: String
    /// Optional item note.
    public let note: String
    /// Optional item photo data.
    public let photoData: Data?
    /// Date when the item was added.
    public let createdAt: Date
    /// Date when the item was archived.
    public let archivedAt: Date?
    /// Marks attached to the item.
    public let marks: [BackupMark]

    /// Creates a backup item payload.
    public init(
        id: UUID,
        name: String,
        categoryRawValue: String,
        note: String,
        photoData: Data?,
        createdAt: Date,
        archivedAt: Date?,
        marks: [BackupMark]
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = categoryRawValue
        self.note = note
        self.photoData = photoData
        self.createdAt = createdAt
        self.archivedAt = archivedAt
        self.marks = marks
    }
}
