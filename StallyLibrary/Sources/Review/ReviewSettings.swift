//
//  ReviewSettings.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Thresholds used to decide which items need gentle review attention.
public struct ReviewSettings: Equatable, Sendable {
    /// Default review thresholds from preserved product intent.
    public static let `default`: ReviewSettings = .init()

    /// Days an unmarked active item can wait before it needs a first mark.
    public let needsFirstMarkAfterDays: Int
    /// Days since last mark before a previously marked active item is dormant.
    public let dormantAfterDays: Int
    /// Minimum mark count for an archived item to become a recovery candidate.
    public let recoveryMinimumMarks: Int

    /// Creates explicit review thresholds.
    public init(
        needsFirstMarkAfterDays: Int = 14,
        dormantAfterDays: Int = 30,
        recoveryMinimumMarks: Int = 1
    ) {
        self.needsFirstMarkAfterDays = max(0, needsFirstMarkAfterDays)
        self.dormantAfterDays = max(0, dormantAfterDays)
        self.recoveryMinimumMarks = max(1, recoveryMinimumMarks)
    }
}
