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
    case importExport = "import-export"
    case createItem = "create-item"

    /// Stable destination identity.
    public var id: String {
        rawValue
    }

    /// User-facing destination title.
    public var title: LocalizedStringResource {
        switch self {
        case .library:
            .init("Library", bundle: #bundle)
        case .archive:
            .init("Archive", bundle: #bundle)
        case .importExport:
            .init("Import & Export", bundle: #bundle)
        case .createItem:
            .init("Create Item", bundle: #bundle)
        }
    }
}
