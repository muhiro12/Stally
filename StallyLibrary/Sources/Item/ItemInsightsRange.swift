import Foundation

/// Time windows used by the collection insights surfaces.
public enum ItemInsightsRange: String, CaseIterable, Codable, Equatable, Sendable {
    case last30Days
    case last90Days
    case last365Days
    case allTime

    /// Human-readable title used by the app surfaces.
    public var title: String {
        switch self {
        case .last30Days:
            "30 Days"
        case .last90Days:
            "90 Days"
        case .last365Days:
            "365 Days"
        case .allTime:
            "All Time"
        }
    }

    /// Fixed day count for bounded windows.
    public var fixedDayCount: Int? {
        switch self {
        case .last30Days:
            30
        case .last90Days:
            90
        case .last365Days:
            365
        case .allTime:
            nil
        }
    }
}
