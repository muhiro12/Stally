//
//  BackupItem.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Portable item payload stored in a Stally backup.
public struct BackupItem: Codable, Equatable, Identifiable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case categoryRawValue
        case note
        case photoData
        case createdAt
        case archivedAt
        case marks
        case recordsMarks
        case start
    }

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
    /// Whether this record participates in choice recording.
    public let recordsMarks: Bool
    /// Canonical partial date, kept raw so export validation can detect corruption.
    public let startRawValue: String?

    var isLegacyCompatible: Bool {
        recordsMarks && startRawValue == nil
    }

    /// Creates a backup item payload.
    public init(
        id: UUID,
        name: String,
        categoryRawValue: String,
        note: String,
        photoData: Data?,
        createdAt: Date,
        archivedAt: Date?,
        marks: [BackupMark],
        recordsMarks: Bool = true,
        startRawValue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = categoryRawValue
        self.note = note
        self.photoData = photoData
        self.createdAt = createdAt
        self.archivedAt = archivedAt
        self.marks = marks
        self.recordsMarks = recordsMarks
        self.startRawValue = startRawValue
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        categoryRawValue = try values.decode(String.self, forKey: .categoryRawValue)
        note = try values.decode(String.self, forKey: .note)
        photoData = try values.decodeIfPresent(Data.self, forKey: .photoData)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        archivedAt = try values.decodeIfPresent(Date.self, forKey: .archivedAt)
        marks = try values.decode([BackupMark].self, forKey: .marks)
        recordsMarks = try values.decode(Bool.self, forKey: .recordsMarks)
        startRawValue = try values.decode(String?.self, forKey: .start)
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encode(categoryRawValue, forKey: .categoryRawValue)
        try values.encode(note, forKey: .note)
        try values.encodeIfPresent(photoData, forKey: .photoData)
        try values.encode(createdAt, forKey: .createdAt)
        try values.encodeIfPresent(archivedAt, forKey: .archivedAt)
        try values.encode(marks, forKey: .marks)
        try values.encode(recordsMarks, forKey: .recordsMarks)
        try values.encode(startRawValue, forKey: .start)
    }
}
