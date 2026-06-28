//
//  CategoryShare.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Category-level share of marks in the selected range.
public struct CategoryShare: Equatable, Sendable {
    /// Category represented by this share.
    public let category: ItemCategory
    /// Mark count for the category.
    public let markCount: Int
    /// Fraction of all marks in the selected range.
    public let fraction: Double

    /// Creates a category share value.
    public init(
        category: ItemCategory,
        markCount: Int,
        fraction: Double
    ) {
        self.category = category
        self.markCount = markCount
        self.fraction = fraction
    }
}
