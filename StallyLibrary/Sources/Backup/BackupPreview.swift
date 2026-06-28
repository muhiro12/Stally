//
//  BackupPreview.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Preview counts for a backup before import.
public struct BackupPreview: Equatable, Sendable {
    /// Items present in the backup.
    public let itemCount: Int
    /// Archived items present in the backup.
    public let archivedItemCount: Int
    /// Marks present in the backup.
    public let markCount: Int
    /// Backup items that already exist locally.
    public let existingItemCount: Int
    /// Backup items that would be added locally.
    public let newItemCount: Int
    /// Backup items skipped because validation failed.
    public let skippedItemCount: Int
    /// Marks that would be added by merge import.
    public let marksAddedCount: Int
    /// Validation issues found in the backup.
    public let validationIssues: [BackupValidationIssue]

    /// Whether the backup can be imported.
    public var canImport: Bool {
        validationIssues.isEmpty
    }

    /// Creates a backup preview.
    public init(
        itemCount: Int,
        archivedItemCount: Int,
        markCount: Int,
        existingItemCount: Int,
        newItemCount: Int,
        skippedItemCount: Int,
        marksAddedCount: Int,
        validationIssues: [BackupValidationIssue]
    ) {
        self.itemCount = itemCount
        self.archivedItemCount = archivedItemCount
        self.markCount = markCount
        self.existingItemCount = existingItemCount
        self.newItemCount = newItemCount
        self.skippedItemCount = skippedItemCount
        self.marksAddedCount = marksAddedCount
        self.validationIssues = validationIssues
    }
}
