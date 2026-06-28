//
//  BackupImportResult.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Result counts after applying a backup import.
public struct BackupImportResult: Equatable, Sendable {
    /// Preview that was applied.
    public let preview: BackupPreview
    /// Items inserted into the local library.
    public let insertedItemCount: Int
    /// Marks inserted into the local library.
    public let insertedMarkCount: Int
    /// Whether the import replaced the current library.
    public let didReplaceLibrary: Bool

    /// Creates an import result.
    public init(
        preview: BackupPreview,
        insertedItemCount: Int,
        insertedMarkCount: Int,
        didReplaceLibrary: Bool
    ) {
        self.preview = preview
        self.insertedItemCount = insertedItemCount
        self.insertedMarkCount = insertedMarkCount
        self.didReplaceLibrary = didReplaceLibrary
    }
}
