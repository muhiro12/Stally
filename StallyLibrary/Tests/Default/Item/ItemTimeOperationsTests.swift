import Foundation
import StallyLibrary
import Testing

@Suite
struct ItemTimeOperationsTests {
    @Test(arguments: ["0001", "9999", "2020-02", "2000-02-29", "2026-09-13"])
    func `partial dates retain their exact precision through encoding`(_ rawValue: String) throws {
        let start = try #require(ItemStart(rawValue: rawValue))
        #expect(start.rawValue == rawValue)
        let data = try JSONEncoder().encode(start)
        #expect(try JSONDecoder().decode(ItemStart.self, from: data) == start)
    }

    @Test(arguments: [
        "", "0", "0000", "10000", "2020-2", "2020-00", "2020-13", "2020-02-30",
        "1900-02-29", "2020-01-1", "２０２０", "2020-01-01Z", "2020--01", " 2020"
    ])
    func `invalid or noncanonical starts are rejected`(_ rawValue: String) {
        #expect(ItemStart(rawValue: rawValue) == nil)
    }

    @Test
    func `readings preserve approximate bounds and unknown starts`() throws {
        let today = try #require(LocalDay(year: 2_026, month: 9, day: 13))
        #expect(ItemTimeOperations.snapshot(start: nil, today: today) == .unknown)
        for (rawValue, expectedDays, expectedUnits) in [
            ("2026-09-13", 0...0, 0...0),
            ("2026-09-01", 12...12, 12...12),
            ("2020-09", 2_174...2_203, 71...72),
            ("2020", 2_082...2_447, 5...6),
            ("2026", 0...255, 0...0)
        ] {
            let start = try #require(ItemStart(rawValue: rawValue))
            #expect(ItemTimeOperations.snapshot(start: start, today: today) == .elapsed(
                start: start, days: expectedDays, units: expectedUnits
            ))
        }
        let future = try #require(ItemStart(rawValue: "2027"))
        #expect(ItemTimeOperations.snapshot(start: future, today: today) == .notStarted(future))
    }

    @Test
    func `month and year anniversaries clamp to the last valid day`() throws {
        let today = try #require(LocalDay(year: 2_025, month: 2, day: 28))
        let month = try #require(ItemStart(rawValue: "2025-01"))
        #expect(ItemTimeOperations.snapshot(start: month, today: today) == .elapsed(
            start: month, days: 28...58, units: 1...1
        ))
        let year = try #require(ItemStart(rawValue: "2024"))
        #expect(ItemTimeOperations.snapshot(start: year, today: today) == .elapsed(
            start: year, days: 59...424, units: 0...1
        ))
    }

    @Test
    func `calendar readings survive DST travel and skipped civil days`() throws {
        let start = try #require(ItemStart(rawValue: "2011-12-30"))
        let followingDay = try #require(LocalDay(year: 2_011, month: 12, day: 31))
        #expect(ItemTimeOperations.snapshot(start: start, today: followingDay) == .elapsed(
            start: start, days: 1...1, units: 1...1
        ))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let instant = try #require(ISO8601DateFormatter().date(from: "2026-03-08T16:00:00Z"))
        let tokyoDay = try #require(LocalDay(containing: instant, in: tokyo))
        let losAngelesDay = try #require(LocalDay(containing: instant, in: losAngeles))
        #expect(losAngelesDay.distance(to: tokyoDay) == 1)
        #expect(start.rawValue == "2011-12-30")
    }

    @Test
    func `refining precision narrows possible elapsed days`() throws {
        let today = try #require(LocalDay(year: 2_026, month: 9, day: 13))
        var previousRange: ClosedRange<Int>?
        for rawValue in ["2020", "2020-09", "2020-09-13"] {
            let start = try #require(ItemStart(rawValue: rawValue))
            guard case .elapsed(_, let days, _) = ItemTimeOperations.snapshot(start: start, today: today) else {
                Issue.record("Expected an elapsed reading")
                return
            }
            if let previousRange {
                #expect(previousRange.contains(days.lowerBound))
                #expect(previousRange.contains(days.upperBound))
            }
            previousRange = days
        }
    }
}
