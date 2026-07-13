//
//  ItemCollectionSort.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

import Foundation

/// Sort orders available while browsing an item collection.
public enum ItemCollectionSort: CaseIterable, Identifiable, Sendable {
    case defaultOrder
    case recentlyMarked
    case mostMarked
    case name
    case category

    public var id: Self {
        self
    }

    /// User-facing sort title.
    public var title: LocalizedStringResource {
        switch self {
        case .defaultOrder:
            .init("Default Order", bundle: #bundle)
        case .recentlyMarked:
            .init("Recently Marked", bundle: #bundle)
        case .mostMarked:
            .init("Most Marked", bundle: #bundle)
        case .name:
            .init("Name", bundle: #bundle)
        case .category:
            .init("Category", bundle: #bundle)
        }
    }
}
