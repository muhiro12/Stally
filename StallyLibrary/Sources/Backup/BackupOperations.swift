//
//  BackupOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Cross-surface Backup Center use cases.
public enum BackupOperations {
    /// Product-facing backup filename extension.
    public static let fileExtension = "stallybackup"
    /// Largest encoded backup file accepted for import.
    public static let maximumImportDataByteCount = 100_663_296
    /// Largest combined photo payload accepted from one backup.
    public static let maximumImportPhotoDataByteCount = 67_108_864
}
