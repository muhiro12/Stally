//
//  InsightsSnapshot.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Collection-wide pattern reading for the selected Insights scope.
public struct InsightsSnapshot {
    /// Scope used to build the reading.
    public let options: InsightsOptions
    /// Total marks in the selected range.
    public let totalMarks: Int
    /// Number of calendar days with at least one mark in the selected range.
    public let activeDays: Int
    /// Number of items marked in the selected range.
    public let uniqueMarkedItems: Int
    /// Number of categories marked in the selected range.
    public let uniqueMarkedCategories: Int
    /// Items with the most marks in the selected range.
    public let topItems: [ItemInsightSummary]
    /// Items with history but no marks in the selected range.
    public let quietItems: [ItemInsightSummary]
    /// Consecutive active days ending today.
    public let currentStreak: Int
    /// Longest consecutive active-day streak in the selected range.
    public let bestStreak: Int
    /// Category share of marks in the selected range.
    public let categoryShares: [CategoryShare]
    /// Note coverage for scoped items.
    public let noteCoverage: CollectionCoverage
    /// Photo coverage for scoped items.
    public let photoCoverage: CollectionCoverage
    /// Quiet next moves grounded in the current reading.
    public let recommendations: [InsightRecommendation]
}
