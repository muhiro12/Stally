import Foundation
import StallyLibrary
import SwiftData
import Testing

@Suite
struct ItemMilestoneTests {
    @Test
    func `milestones retain uncertainty until their entire period passes`() throws {
        let today = try #require(LocalDay(year: 2_026, month: 9, day: 14))
        for (rawValue, expectedPeriod, years) in [
            ("2020", "2026", 6), ("2020-09", "2026-09", 6),
            ("2020-08", "2027-08", 7), ("2020-09-14", "2026-09-14", 6),
            ("2020-09-13", "2027-09-13", 7), ("2026-09-14", "2027-09-14", 1)
        ] {
            let start = try #require(ItemStart(rawValue: rawValue))
            let milestone = try #require(ItemTimeOperations.milestone(start: start, today: today))
            #expect(milestone.period.rawValue == expectedPeriod)
            #expect(milestone.period.precision == start.precision)
            #expect(milestone.years == years)
        }
        #expect(ItemTimeOperations.milestone(start: nil, today: today) == nil)
        #expect(ItemTimeOperations.milestone(start: ItemStart(rawValue: "2027"), today: today) == nil)
    }

    @Test
    func `leap days and representable year limits remain calendar safe`() throws {
        let start = try #require(ItemStart(rawValue: "2024-02-29"))
        for (today, expected) in [
            (LocalDay(year: 2_025, month: 2, day: 28), "2025-02-28"),
            (LocalDay(year: 2_025, month: 3, day: 1), "2026-02-28"),
            (LocalDay(year: 2_028, month: 2, day: 29), "2028-02-29")
        ] {
            #expect(ItemTimeOperations.milestone(start: start, today: try #require(today))?.period.rawValue == expected)
        }
        let lastDay = try #require(LocalDay(year: 9_999, month: 12, day: 31))
        #expect(ItemTimeOperations.milestone(start: ItemStart(rawValue: "9999"), today: lastDay) == nil)
        #expect(ItemTimeOperations.milestone(start: ItemStart(rawValue: "9998-01-01"), today: lastDay) == nil)
        #expect(ItemTimeOperations.milestone(start: ItemStart(rawValue: "0001"), today: lastDay)?.years == 9_998)
    }
}

extension SwiftDataOperationsTests {
    @Suite
    struct ItemMilestonePersistenceTests {
        @Test
        func `milestone reads preserve identity history photos and archive continuity`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 14))
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: "Bag", category: .bags, photoData: try TestPhotoFixtures.preparedData()),
                tracking: .init(recordsMarks: true, start: try #require(ItemStart(rawValue: "2020-09"))),
                today: today
            )
            try ItemOperations.mark(item, on: today, today: today, context: context)
            let identifier = item.uuid
            let markIdentifier = item.marks.first?.uuid
            let photo = item.photoData
            let before = ItemTimeOperations.milestone(for: item, today: today)
            try ItemOperations.archive(item, on: .now, context: context)
            let createdAt = item.createdAt
            #expect(ItemTimeOperations.milestone(for: item, today: today) == before)
            #expect(item.uuid == identifier)
            #expect(item.marks.first?.uuid == markIdentifier)
            #expect(item.photoData == photo)
            #expect(item.createdAt == createdAt)
            #expect(!context.hasChanges)
            try ItemOperations.moveBackToLibrary(item, context: context)
            #expect(ItemTimeOperations.milestone(for: item, today: today) == before)
        }
    }
}
