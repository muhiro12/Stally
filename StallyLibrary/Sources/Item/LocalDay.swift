//
//  LocalDay.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/07/12.
//

import Foundation

/// A timezone-independent day in the proleptic Gregorian calendar.
public struct LocalDay: Codable, Comparable, Hashable, Sendable {
    private enum Limits {
        static let minimumYear = 1
        static let maximumYear = 9_999
        static let minimumMonth = 1
        static let maximumMonth = 12
        static let minimumDay = 1
    }

    private enum Gregorian {
        static let daysPer400Years = 146_097
        static let daysFromCivilEpochToUnixEpoch = 719_468
    }

    private enum StorageKey {
        static let yearMultiplier = 10_000
        static let monthMultiplier = 100
    }

    /// The Gregorian calendar year.
    public let year: Int
    /// The Gregorian calendar month, from 1 through 12.
    public let month: Int
    /// The Gregorian calendar day of the month.
    public let day: Int

    /// Canonical ISO 8601 full-date representation.
    public var iso8601Date: String {
        canonicalValue
    }

    /// Compact numeric representation used by SwiftData storage.
    var dayKey: Int {
        year * StorageKey.yearMultiplier + month * StorageKey.monthMultiplier + day
    }

    /// Creates a day when the supplied proleptic Gregorian components are valid.
    public init?(year: Int, month: Int, day: Int) {
        guard (Limits.minimumYear...Limits.maximumYear).contains(year),
              (Limits.minimumMonth...Limits.maximumMonth).contains(month),
              (Limits.minimumDay...Self.numberOfDays(inMonth: month, year: year)).contains(day) else {
            return nil
        }

        self.year = year
        self.month = month
        self.day = day
    }

    /// Captures the local Gregorian day containing an absolute date in a timezone.
    public init?(containing date: Date, in timeZone: TimeZone) {
        let components = Self.calendar(in: timeZone).dateComponents(
            [.year, .month, .day],
            from: date
        )

        guard let resolvedYear = components.year,
              let resolvedMonth = components.month,
              let resolvedDay = components.day else {
            return nil
        }

        self.init(year: resolvedYear, month: resolvedMonth, day: resolvedDay)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encodedDay = try container.decode(String.self)

        guard let localDay = Self(canonicalValue: encodedDay) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a valid proleptic Gregorian day in YYYY-MM-DD format."
            )
        }

        self = localDay
    }

    /// Restores a day from its compact SwiftData storage representation.
    init?(dayKey: Int) {
        let resolvedYear = dayKey / StorageKey.yearMultiplier
        let resolvedMonth = dayKey / StorageKey.monthMultiplier % StorageKey.monthMultiplier
        let resolvedDay = dayKey % StorageKey.monthMultiplier

        self.init(year: resolvedYear, month: resolvedMonth, day: resolvedDay)

        guard self.dayKey == dayKey else {
            return nil
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.dayOrdinal < rhs.dayOrdinal
    }

    /// Returns the first representable instant of this day in a timezone.
    ///
    /// A result is unavailable when Foundation cannot represent this proleptic
    /// Gregorian day in the requested timezone.
    public func date(in timeZone: TimeZone) -> Date? {
        let calendar = Self.calendar(in: timeZone)
        let components = DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: year,
            month: month,
            day: day
        )

        guard let date = calendar.date(from: components),
              Self(containing: date, in: timeZone) == self else {
            return nil
        }

        return calendar.startOfDay(for: date)
    }

    /// Returns the day offset by a number of proleptic Gregorian days.
    public func adding(days dayCount: Int) -> Self? {
        let (ordinal, overflow) = dayOrdinal.addingReportingOverflow(dayCount)

        guard !overflow else {
            return nil
        }

        return Self(dayOrdinal: ordinal)
    }

    /// Returns the number of proleptic Gregorian days from this day to another day.
    public func distance(to other: Self) -> Int {
        other.dayOrdinal - dayOrdinal
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(canonicalValue)
    }
}

// The fixed values below define the proleptic Gregorian conversion algorithm.
// swiftlint:disable no_magic_numbers
private extension LocalDay {
    var canonicalValue: String {
        String(
            format: "%04d-%02d-%02d",
            locale: .init(identifier: "en_US_POSIX"),
            year,
            month,
            day
        )
    }

    var dayOrdinal: Int {
        let adjustedYear = year - (month <= 2 ? 1 : 0)
        let era = adjustedYear / 400
        let yearOfEra = adjustedYear - era * 400
        let adjustedMonth = month + (month > 2 ? -3 : 9)
        let dayOfYear = (153 * adjustedMonth + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear

        return era * Gregorian.daysPer400Years
            + dayOfEra
            - Gregorian.daysFromCivilEpochToUnixEpoch
    }

    init?(canonicalValue: String) {
        let characters = Array(canonicalValue.utf8)

        guard characters.count == 10,
              characters[4] == UInt8(ascii: "-"),
              characters[7] == UInt8(ascii: "-"),
              let year = Self.integer(from: characters[0...3]),
              let month = Self.integer(from: characters[5...6]),
              let day = Self.integer(from: characters[8...9]) else {
            return nil
        }

        self.init(year: year, month: month, day: day)
    }

    init?(dayOrdinal: Int) {
        let shiftedOrdinal = dayOrdinal + Gregorian.daysFromCivilEpochToUnixEpoch
        let era = shiftedOrdinal >= 0
            ? shiftedOrdinal / Gregorian.daysPer400Years
            : (shiftedOrdinal - (Gregorian.daysPer400Years - 1)) / Gregorian.daysPer400Years
        let dayOfEra = shiftedOrdinal - era * Gregorian.daysPer400Years
        let yearOfEra = (
            dayOfEra
                - dayOfEra / 1_460
                + dayOfEra / 36_524
                - dayOfEra / (Gregorian.daysPer400Years - 1)
        ) / 365
        let provisionalYear = yearOfEra + era * 400
        let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
        let monthPrime = (5 * dayOfYear + 2) / 153
        let day = dayOfYear - (153 * monthPrime + 2) / 5 + 1
        let month = monthPrime + (monthPrime < 10 ? 3 : -9)
        let year = provisionalYear + (month <= 2 ? 1 : 0)

        self.init(year: year, month: month, day: day)
    }

    static func integer(from characters: ArraySlice<UInt8>) -> Int? {
        var result = 0

        for character in characters {
            guard character >= UInt8(ascii: "0"),
                  character <= UInt8(ascii: "9") else {
                return nil
            }

            result = result * 10 + Int(character - UInt8(ascii: "0"))
        }

        return result
    }

    static func numberOfDays(inMonth month: Int, year: Int) -> Int {
        switch month {
        case 2:
            isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            30
        default:
            31
        }
    }

    static func isLeapYear(_ year: Int) -> Bool {
        year.isMultiple(of: 400)
            || (year.isMultiple(of: 4) && !year.isMultiple(of: 100))
    }

    static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .init(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        return calendar
    }
}
// swiftlint:enable no_magic_numbers
