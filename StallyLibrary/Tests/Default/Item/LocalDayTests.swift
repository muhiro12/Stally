//
//  LocalDayTests.swift
//  StallyLibraryTests
//
//  Created by Hiromu Nakano on 2026/07/12.
//

import Foundation
@testable import StallyLibrary
import Testing

struct LocalDayTests {
    private static func date(
        from components: DateComponents,
        in timeZone: TimeZone
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var configuredComponents = components
        configuredComponents.calendar = calendar
        configuredComponents.timeZone = timeZone
        return calendar.date(from: configuredComponents)
    }

    @Test
    func `initializer rejects invalid Gregorian components`() {
        #expect(LocalDay(year: 0, month: 1, day: 1) == nil)
        #expect(LocalDay(year: 10_000, month: 1, day: 1) == nil)
        #expect(LocalDay(year: 2_026, month: 0, day: 1) == nil)
        #expect(LocalDay(year: 2_026, month: 13, day: 1) == nil)
        #expect(LocalDay(year: 2_026, month: 1, day: 0) == nil)
        #expect(LocalDay(year: 2_026, month: 4, day: 31) == nil)
        #expect(LocalDay(year: 2_025, month: 2, day: 29) == nil)
        #expect(LocalDay(year: 1_900, month: 2, day: 29) == nil)
    }

    @Test
    func `initializer accepts proleptic Gregorian leap days`() throws {
        let leapDay = try #require(LocalDay(year: 2_024, month: 2, day: 29))
        let fourHundredYearLeapDay = try #require(LocalDay(year: 2_000, month: 2, day: 29))

        #expect(leapDay.year == 2_024)
        #expect(fourHundredYearLeapDay.day == 29)
    }

    @Test
    func `day addition crosses month and year boundaries`() throws {
        let yearEnd = try #require(LocalDay(year: 2_026, month: 12, day: 31))
        let leapMonthEnd = try #require(LocalDay(year: 2_024, month: 2, day: 29))

        #expect(yearEnd.adding(days: 1) == LocalDay(year: 2_027, month: 1, day: 1))
        #expect(leapMonthEnd.adding(days: 1) == LocalDay(year: 2_024, month: 3, day: 1))
        #expect(yearEnd.adding(days: -31) == LocalDay(year: 2_026, month: 11, day: 30))
    }

    @Test
    func `day arithmetic remains proleptic across the Gregorian reform`() throws {
        let beforeHistoricalReform = try #require(LocalDay(year: 1_582, month: 10, day: 4))
        let nextDay = try #require(LocalDay(year: 1_582, month: 10, day: 5))

        #expect(beforeHistoricalReform.adding(days: 1) == nextDay)
        #expect(beforeHistoricalReform.distance(to: nextDay) == 1)
        #expect(nextDay.distance(to: beforeHistoricalReform) == -1)
    }

    @Test
    func `day addition remains inside the canonical year range`() throws {
        let firstDay = try #require(LocalDay(year: 1, month: 1, day: 1))
        let lastDay = try #require(LocalDay(year: 9_999, month: 12, day: 31))

        #expect(firstDay.adding(days: -1) == nil)
        #expect(lastDay.adding(days: 1) == nil)
    }

    @Test
    func `comparison follows chronological day order`() throws {
        let earlierDay = try #require(LocalDay(year: 2_026, month: 6, day: 25))
        let laterDay = try #require(LocalDay(year: 2_026, month: 6, day: 26))

        #expect(earlierDay < laterDay)
        #expect([laterDay, earlierDay].sorted() == [earlierDay, laterDay])
    }

    @Test
    func `los Angeles daylight saving transition preserves civil day arithmetic`() throws {
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let transitionDay = try #require(LocalDay(year: 2_026, month: 3, day: 8))
        let followingDay = try #require(transitionDay.adding(days: 1))
        let transitionStart = try #require(transitionDay.date(in: losAngeles))
        let followingStart = try #require(followingDay.date(in: losAngeles))

        #expect(transitionDay.distance(to: followingDay) == 1)
        #expect(followingStart.timeIntervalSince(transitionStart) == 23 * 60 * 60)
        #expect(LocalDay(containing: followingStart, in: losAngeles) == followingDay)
    }

    @Test
    func `captured Tokyo day keeps its identity when displayed in Los Angeles`() throws {
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let instant = try #require(
            Self.date(
                from: .init(
                    year: 2_026,
                    month: 6,
                    day: 25,
                    hour: 15,
                    minute: 30
                ),
                in: utc
            )
        )
        let tokyoDay = try #require(LocalDay(containing: instant, in: tokyo))
        let losAngelesDayAtSameInstant = try #require(LocalDay(containing: instant, in: losAngeles))
        let tokyoDayDisplayedInLosAngeles = try #require(tokyoDay.date(in: losAngeles))

        #expect(tokyoDay == LocalDay(year: 2_026, month: 6, day: 26))
        #expect(losAngelesDayAtSameInstant == LocalDay(year: 2_026, month: 6, day: 25))
        #expect(LocalDay(containing: tokyoDayDisplayedInLosAngeles, in: losAngeles) == tokyoDay)
    }

    @Test
    func `date capture ignores non Gregorian calendar construction`() throws {
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        var buddhistCalendar = Calendar(identifier: .buddhist)
        buddhistCalendar.timeZone = utc
        let buddhistComponents = DateComponents(
            calendar: buddhistCalendar,
            timeZone: utc,
            year: 2_569,
            month: 6,
            day: 26
        )
        let instant = try #require(buddhistCalendar.date(from: buddhistComponents))

        #expect(LocalDay(containing: instant, in: utc) == LocalDay(year: 2_026, month: 6, day: 26))
    }

    @Test
    func `swiftData day key round trips valid days`() throws {
        let day = try #require(LocalDay(year: 2_026, month: 6, day: 26))

        #expect(day.dayKey == 20_260_626)
        #expect(LocalDay(dayKey: day.dayKey) == day)
        #expect(LocalDay(dayKey: 20_260_631) == nil)
        #expect(LocalDay(dayKey: 2_026_626) == nil)
    }

    @Test
    func `codable uses one canonical string`() throws {
        let day = try #require(LocalDay(year: 2_026, month: 6, day: 3))
        let data = try JSONEncoder().encode(day)
        let encodedDay = try #require(String(data: data, encoding: .utf8))

        #expect(encodedDay == #""2026-06-03""#)
        #expect(try JSONDecoder().decode(LocalDay.self, from: data) == day)
    }

    @Test(
        arguments: [
            #""2026-6-03""#,
            #""2026-06-3""#,
            #""2025-02-29""#,
            #""0000-01-01""#,
            #""10000-01-01""#,
            #""2026-06-03Z""#,
            #""２０２６-０６-０３""#,
            #"{"year":2026,"month":6,"day":3}"#
        ]
    )
    func `codable rejects noncanonical or invalid values`(_ encodedValue: String) {
        let data = Data(encodedValue.utf8)

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(LocalDay.self, from: data)
        }
    }
}
