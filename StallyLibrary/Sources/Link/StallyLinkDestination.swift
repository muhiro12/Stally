//
//  StallyLinkDestination.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Major Stally destinations that can be opened from a shareable link.
public enum StallyLinkDestination: String, CaseIterable, Codable, Identifiable, Sendable {
    case library
    case archive
    case review
    case insights
    case backupCenter = "backup-center"
    case createItem = "create-item"
    case settings

    /// Stable destination identity.
    public var id: String {
        rawValue
    }

    /// User-facing destination title.
    public var title: LocalizedStringResource {
        switch self {
        case .library:
            "Library"
        case .archive:
            "Archive"
        case .review:
            "Review"
        case .insights:
            "Insights"
        case .backupCenter:
            "Backup Center"
        case .createItem:
            "Create Item"
        case .settings:
            "Settings"
        }
    }
}
