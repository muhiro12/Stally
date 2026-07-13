//
//  InsightsRange.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Time windows for reading collection patterns.
public enum InsightsRange: String, CaseIterable, Equatable, Hashable, Identifiable, Sendable {
    case thirtyDays = "thirty-days"
    case ninetyDays = "ninety-days"
    case year
    case allTime = "all-time"

    private static let thirtyDayStartOffset = -29
    private static let ninetyDayStartOffset = -89
    private static let yearStartOffset = -364

    /// Stable range identity.
    public var id: Self {
        self
    }

    /// User-facing range title.
    public var title: LocalizedStringResource {
        switch self {
        case .allTime:
            .init("All Time", bundle: #bundle)
        case .ninetyDays:
            .init("90 Days", bundle: #bundle)
        case .thirtyDays:
            .init("30 Days", bundle: #bundle)
        case .year:
            .init("365 Days", bundle: #bundle)
        }
    }

    func startDay(from today: LocalDay) -> LocalDay? {
        switch self {
        case .allTime:
            nil
        case .ninetyDays:
            today.adding(days: Self.ninetyDayStartOffset)
        case .thirtyDays:
            today.adding(days: Self.thirtyDayStartOffset)
        case .year:
            today.adding(days: Self.yearStartOffset)
        }
    }
}
