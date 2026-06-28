//
//  CollectionCoverage.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Coverage ratio for optional item context.
public struct CollectionCoverage: Equatable, Sendable {
    /// Items with the context present.
    public let coveredCount: Int
    /// Items included in the reading scope.
    public let totalCount: Int

    /// Fraction of scoped items with the context present.
    public var fraction: Double {
        guard totalCount > 0 else {
            return 0
        }

        return Double(coveredCount) / Double(totalCount)
    }

    /// Creates a collection coverage value.
    public init(coveredCount: Int, totalCount: Int) {
        self.coveredCount = coveredCount
        self.totalCount = totalCount
    }
}
