//
//  MonthlyActivity.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

/// Mark activity for one Gregorian calendar month.
public struct MonthlyActivity: Equatable, Identifiable, Sendable {
    public let year: Int
    public let month: Int
    public let markCount: Int

    public var id: Int {
        year * 100 + month
    }

    public init(year: Int, month: Int, markCount: Int) {
        self.year = year
        self.month = month
        self.markCount = markCount
    }
}
