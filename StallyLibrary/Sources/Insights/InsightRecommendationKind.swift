//
//  InsightRecommendationKind.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Recommendation categories generated from the current collection reading.
public enum InsightRecommendationKind: Equatable, Sendable {
    case addContextToFrequentItems
    case protectCurrentStreak
    case revisitQuietFavorites
    case startThisRangeWithOneMark

    /// User-facing recommendation title.
    public var title: LocalizedStringResource {
        switch self {
        case .addContextToFrequentItems:
            "Add context to your frequent items"
        case .protectCurrentStreak:
            "Protect the current streak"
        case .revisitQuietFavorites:
            "Revisit quiet favorites"
        case .startThisRangeWithOneMark:
            "Start this range with one mark"
        }
    }

    /// Quiet explanation of the recommended next move.
    public var summary: LocalizedStringResource {
        switch self {
        case .addContextToFrequentItems:
            "Frequent active items without notes may be easier to read later with short context."
        case .protectCurrentStreak:
            "An active streak is already in motion."
        case .revisitQuietFavorites:
            "Items with history but no marks in this range may deserve a gentle revisit."
        case .startThisRangeWithOneMark:
            "No marks in the selected range yet."
        }
    }
}
