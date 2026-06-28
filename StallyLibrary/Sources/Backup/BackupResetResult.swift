//
//  BackupResetResult.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Result counts after intentionally deleting the local library.
public struct BackupResetResult: Equatable, Sendable {
    /// Deleted item count.
    public let deletedItemCount: Int
    /// Deleted mark count.
    public let deletedMarkCount: Int

    /// Creates a reset result.
    public init(deletedItemCount: Int, deletedMarkCount: Int) {
        self.deletedItemCount = deletedItemCount
        self.deletedMarkCount = deletedMarkCount
    }
}
