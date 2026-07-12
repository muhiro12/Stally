//
//  ItemInsightSummary.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Item-level contribution to the current Insights reading.
public struct ItemInsightSummary {
    /// Item represented by this insight.
    public let item: Item
    /// Marks inside the selected range.
    public let marksInRange: Int
    /// Total marks across all history.
    public let totalMarks: Int
    /// Most recent marked day across all history.
    public let lastMarkedDay: LocalDay?
}
