//
//  BackupValidationIssue.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// A validation issue found while preparing a backup import.
public struct BackupValidationIssue: Equatable, Identifiable, Sendable {
    /// Validation issue categories.
    public enum Kind: String, Equatable, Sendable {
        case duplicateCurrentItemID
        case duplicateItemID
        case duplicateMarkDay
        case duplicateMarkID
        case itemNameRequired
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
        case .duplicateCurrentItemID:
            .init("Duplicate Current Item ID", bundle: #bundle)
        case .duplicateItemID:
            .init("Duplicate Item ID", bundle: #bundle)
        case .duplicateMarkDay:
            .init("Duplicate Mark Day", bundle: #bundle)
        case .duplicateMarkID:
            .init("Duplicate Mark ID", bundle: #bundle)
        case .itemNameRequired:
            .init("Item name is required.", bundle: #bundle)
        case .unknownCategory:
            .init("Unknown Category", bundle: #bundle)
        case .unreadableBackup:
            .init("Unreadable Backup", bundle: #bundle)
        case .unsupportedSchemaVersion:
            .init("Unsupported Schema Version", bundle: #bundle)
        }
    }

    /// Creates a validation issue.
    public init(kind: Kind, value: String? = nil) {
        self.kind = kind
        self.value = value
        id = "\(kind.rawValue):\(value ?? "")"
    }
}
