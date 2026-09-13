import Foundation

/// Known Gregorian start components, without inventing missing month or day values.
public struct ItemStart: RawRepresentable, Hashable, Codable, Sendable {
    /// The precision supplied by the person who entered the start.
    public enum Precision: String, CaseIterable, Codable, Sendable {
        case year
        case month
        case day
    }

    private static let yearLength = 4
    private static let monthLength = 7
    private static let lastMonth = 12
    private static let lastDay = 31
    private static let shortestMonth = 28
    private static let maximumComponentCount = 3
    private static let dayComponentIndex = 2

    /// Precision retained when storing, exporting, and presenting this start.
    public let precision: Precision
    /// Earliest possible start; this bound is not an inferred exact start.
    public let earliestDay: LocalDay
    /// Latest possible start, including the end of a partially known period.
    public let latestDay: LocalDay

    /// Canonical ASCII partial date, suitable for a single persisted scalar.
    public var rawValue: String {
        switch precision {
        case .year:
            String(earliestDay.iso8601Date.prefix(Self.yearLength))
        case .month:
            String(earliestDay.iso8601Date.prefix(Self.monthLength))
        case .day:
            earliestDay.iso8601Date
        }
    }

    /// Creates a start only when the supplied component combination is valid.
    public init?(year: Int, month: Int? = nil, day: Int? = nil) {
        guard day == nil || month != nil,
              let first = LocalDay(year: year, month: month ?? 1, day: day ?? 1),
              let last = LocalDay(
                year: year,
                month: month ?? Self.lastMonth,
                day: day ?? Self.lastValidDay(year: year, month: month ?? Self.lastMonth)
              ) else {
            return nil
        }

        precision = day != nil ? .day : (month != nil ? .month : .year)
        earliestDay = first
        latestDay = last
    }

    /// Parses only canonical YYYY, YYYY-MM, or YYYY-MM-DD values.
    public init?(rawValue: String) {
        let parts = rawValue.split(separator: "-", omittingEmptySubsequences: false)
        guard (1...Self.maximumComponentCount).contains(parts.count),
              parts.allSatisfy({ part in
                !part.isEmpty && part.utf8.allSatisfy { byte in
                    byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
                }
              }),
              let year = Int(parts[0]) else {
            return nil
        }

        let month = parts.count > 1 ? Int(parts[1]) : nil
        let day = parts.count > Self.dayComponentIndex ? Int(parts[Self.dayComponentIndex]) : nil
        self.init(year: year, month: month, day: day)
        guard self.rawValue == rawValue else {
            return nil
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encodedStart = try container.decode(String.self)
        guard let start = Self(rawValue: encodedStart) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a valid Gregorian partial date."
            )
        }
        self = start
    }

    static func lastValidDay(year: Int, month: Int) -> Int {
        (Self.shortestMonth...Self.lastDay).reversed().first { day in
            LocalDay(year: year, month: month, day: day) != nil
        } ?? Self.shortestMonth
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
