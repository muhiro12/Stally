//
//  BackupValidationIssue.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// A validation issue found while reading a backup.
public struct BackupValidationIssue: Equatable, Identifiable, Sendable {
    /// Validation issue categories.
    public enum Kind: String, Equatable, Sendable {
        case duplicateItemID
        case duplicateMarkID
        case unknownCategory
        case unreadableBackup
        case unsupportedSchemaVersion
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
        case .duplicateItemID:
            "Duplicate Item ID"
        case .duplicateMarkID:
            "Duplicate Mark ID"
        case .unknownCategory:
            "Unknown Category"
        case .unreadableBackup:
            "Unreadable Backup"
        case .unsupportedSchemaVersion:
            "Unsupported Schema Version"
        }
    }

    /// Creates a validation issue.
    public init(kind: Kind, value: String? = nil) {
        self.kind = kind
        self.value = value
        id = "\(kind.rawValue):\(value ?? "")"
    }
}
