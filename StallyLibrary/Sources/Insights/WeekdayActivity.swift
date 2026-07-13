//
//  WeekdayActivity.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

/// Mark activity for one Gregorian weekday.
public struct WeekdayActivity: Equatable, Identifiable, Sendable {
    /// Foundation weekday number, where Sunday is 1 and Saturday is 7.
    public let weekday: Int
    /// Marks recorded on this weekday inside the selected range.
    public let markCount: Int

    public var id: Int {
        weekday
    }

    public init(weekday: Int, markCount: Int) {
        self.weekday = weekday
        self.markCount = markCount
    }
}
