//
//  BackupError.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Backup operation failures that callers can surface safely.
public enum BackupError: Error, Equatable {
    case validationFailed(BackupPreview)
}
