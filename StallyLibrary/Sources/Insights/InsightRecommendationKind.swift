//
//  InsightRecommendationKind.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Recommendation categories generated from the current collection reading.
public enum InsightRecommendationKind: Equatable, Hashable, Identifiable, Sendable {
    case addContextToFrequentItems
    case protectCurrentStreak
    case revisitQuietFavorites
    case startThisRangeWithOneMark

    /// Stable recommendation identity.
    public var id: Self {
        self
    }

    /// User-facing recommendation title.
    public var title: LocalizedStringResource {
        switch self {
        case .addContextToFrequentItems:
            .init("Add context to your frequent items", bundle: #bundle)
        case .protectCurrentStreak:
            .init("Protect the current streak", bundle: #bundle)
        case .revisitQuietFavorites:
            .init("Revisit quiet favorites", bundle: #bundle)
        case .startThisRangeWithOneMark:
            .init("Start this range with one mark", bundle: #bundle)
        }
    }

    /// Quiet explanation of the recommended next move.
    public var summary: LocalizedStringResource {
        switch self {
        case .addContextToFrequentItems:
            .init(
                "Frequent active items without notes may be easier to read later with short context.",
                bundle: #bundle
            )
        case .protectCurrentStreak:
            .init("An active streak is already in motion.", bundle: #bundle)
        case .revisitQuietFavorites:
            .init(
                "Items with history but no marks in this range may deserve a gentle revisit.",
                bundle: #bundle
            )
        case .startThisRangeWithOneMark:
            .init("No marks in the selected range yet.", bundle: #bundle)
        }
    }
}
