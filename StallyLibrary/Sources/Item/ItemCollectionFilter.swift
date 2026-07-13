//
//  ItemCollectionFilter.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

import Foundation

/// Mark-history filters available while browsing an item collection.
public enum ItemCollectionFilter: CaseIterable, Identifiable, Sendable {
    case all
    case openToday
    case markedToday
    case openOnDay
    case markedOnDay
    case neverMarked
    case withHistory
    case withoutHistory

    public var id: Self {
        self
    }

    /// User-facing filter title.
    public var title: LocalizedStringResource {
        switch self {
        case .all:
            .init("All", bundle: #bundle)
        case .openToday:
            .init("Open Today", bundle: #bundle)
        case .markedToday:
            .init("Marked Today", bundle: #bundle)
        case .openOnDay:
            .init("Open on Day", bundle: #bundle)
        case .markedOnDay:
            .init("Marked on Day", bundle: #bundle)
        case .neverMarked:
            .init("Never Marked", bundle: #bundle)
        case .withHistory:
            .init("With History", bundle: #bundle)
        case .withoutHistory:
            .init("Without History", bundle: #bundle)
        }
    }
}
