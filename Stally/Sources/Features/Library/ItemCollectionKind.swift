//
//  ItemCollectionKind.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import Foundation

enum ItemCollectionKind {
    case library
    case archive

    var availableFilters: [ItemCollectionFilter] {
        switch self {
        case .library:
            [
                .all,
                .openToday,
                .markedToday,
                .openOnDay,
                .markedOnDay,
                .neverMarked,
                .withHistory
            ]
        case .archive:
            [.all, .withHistory, .withoutHistory]
        }
    }

    var searchPrompt: LocalizedStringResource {
        switch self {
        case .library:
            "Search items"
        case .archive:
            "Search archive"
        }
    }

    var noMatchesTitle: LocalizedStringResource {
        switch self {
        case .library:
            "No Matching Items"
        case .archive:
            "No Matching Archived Items"
        }
    }
}
