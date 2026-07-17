//
//  SampleDataSummary.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/17.
//

/// Counts the built-in sample records currently present in a Library.
public struct SampleDataSummary: Equatable, Sendable {
    /// Number of sample items, including archived items.
    public let itemCount: Int
    /// Number of marks attached to the sample items.
    public let markCount: Int

    /// Whether no built-in sample items remain.
    public var isEmpty: Bool {
        itemCount == 0
    }

    /// Creates a summary of built-in sample records.
    public init(itemCount: Int, markCount: Int) {
        self.itemCount = itemCount
        self.markCount = markCount
    }
}
