//
//  BackupMark.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Portable mark payload stored in a Stally backup.
public struct BackupMark: Codable, Equatable, Identifiable, Sendable {
    /// Stable mark identifier.
    public let id: UUID
    /// Marked calendar day.
    public let day: Date
    /// Date when the mark record was created.
    public let createdAt: Date

    /// Creates a backup mark payload.
    public init(id: UUID, day: Date, createdAt: Date) {
        self.id = id
        self.day = day
        self.createdAt = createdAt
    }
}
