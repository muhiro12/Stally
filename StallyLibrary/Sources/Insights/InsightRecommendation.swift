//
//  InsightRecommendation.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// One quiet next move derived from the current collection reading.
public struct InsightRecommendation: Equatable, Sendable {
    /// Recommendation category.
    public let kind: InsightRecommendationKind

    /// User-facing recommendation title.
    public var title: LocalizedStringResource {
        kind.title
    }

    /// Quiet explanation of the recommended next move.
    public var summary: LocalizedStringResource {
        kind.summary
    }

    /// Creates an insight recommendation.
    public init(kind: InsightRecommendationKind) {
        self.kind = kind
    }
}
