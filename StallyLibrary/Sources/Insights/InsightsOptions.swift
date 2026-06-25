//
//  InsightsOptions.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// User-controllable scope for an Insights reading.
public struct InsightsOptions: Equatable, Sendable {
    /// Default Insights scope.
    public static let `default`: InsightsOptions = .init()

    /// Selected reading window.
    public let range: InsightsRange
    /// Whether archived items are included in the reading.
    public let includesArchivedItems: Bool

    /// Creates an Insights scope.
    public init(
        range: InsightsRange = .thirtyDays,
        includesArchivedItems: Bool = false
    ) {
        self.range = range
        self.includesArchivedItems = includesArchivedItems
    }
}
