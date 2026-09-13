//
//  BackupValidationIssue.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// A validation issue found while preparing a backup export or import.
public struct BackupValidationIssue: Equatable, Identifiable, Sendable {
    /// Validation issue categories.
    public enum Kind: String, Equatable, Sendable {
        case backupFileTooLarge
        case duplicateCurrentItemID
        case duplicateItemID
        case duplicateMarkDay
        case duplicateMarkID
        case invalidItemPhoto
        case itemNameRequired
        case photoStorageLimitExceeded
        case unknownCategory
        case unreadableBackup
        case unsupportedSchemaVersion
        case invalidItemStart
        case nonMarkHistoryConflict
        case markPolicyMergeConflict
        case unsupportedTrackingFields
    }

    /// Stable issue identity.
    public let id: String
    /// Validation issue category.
    public let kind: Kind
    /// Affected raw value when one exists.
    public let value: String?

    /// User-facing issue title.
    public var title: LocalizedStringResource {
        switch kind {
        case .backupFileTooLarge:
            .init("Backup File Too Large", bundle: #bundle)
        case .duplicateCurrentItemID:
            .init("Duplicate Current Item ID", bundle: #bundle)
        case .duplicateItemID:
            .init("Duplicate Item ID", bundle: #bundle)
        case .duplicateMarkDay:
            .init("Duplicate Mark Day", bundle: #bundle)
        case .duplicateMarkID:
            .init("Duplicate Mark ID", bundle: #bundle)
        case .invalidItemPhoto:
            .init("Invalid Item Photo", bundle: #bundle)
        case .itemNameRequired:
            .init("Item name is required.", bundle: #bundle)
        case .photoStorageLimitExceeded:
            .init("Backup Photo Storage Limit Exceeded", bundle: #bundle)
        case .unknownCategory:
            .init("Unknown Category", bundle: #bundle)
        case .unreadableBackup:
            .init("Unreadable Backup", bundle: #bundle)
        case .unsupportedSchemaVersion:
            .init("Unsupported Schema Version", bundle: #bundle)
        case .invalidItemStart:
            .init("Invalid Item Start", bundle: #bundle)
        case .nonMarkHistoryConflict:
            .init("Enable Marks to Preserve Existing History", bundle: #bundle)
        case .markPolicyMergeConflict:
            .init("Merge Requires Marks Enabled for This Item", bundle: #bundle)
        case .unsupportedTrackingFields:
            .init("Tracking Fields Require Backup Version 3", bundle: #bundle)
        }
    }

    /// Creates a validation issue.
    public init(kind: Kind, value: String? = nil) {
        self.kind = kind
        self.value = value
        id = "\(kind.rawValue):\(value ?? "")"
    }
}
