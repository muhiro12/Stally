import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ReviewIdentifiersSnapshotTests {
        @Test
        func `identifier lanes share the app reading and preserve captured membership`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            context.autosaveEnabled = false
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 30))
            let past = try #require(today.adding(days: -60)?.date(in: .gmt))
            let now = try #require(today.date(in: .gmt))
            let waiting = try ItemOperations.create(
                context: context, input: .init(name: "Bag", category: .bags), createdAt: past
            )
            let place = try ItemOperations.create(
                context: context,
                input: .init(name: "Home", category: .other),
                tracking: .init(markPolicy: .disabled, start: nil),
                today: today,
                createdAt: past
            )
            let items = [waiting, place]
            let live = ReviewOperations.snapshot(for: items, timeZone: .gmt, now: now)
            let captured = ReviewOperations.identifiersSnapshot(for: items, timeZone: .gmt, now: now)
            for lane in ReviewLane.allCases {
                #expect(captured.itemIDs(in: lane) == live.items(in: lane).map(\.uuid))
                #expect(!captured.itemIDs(in: lane).contains(place.uuid))
            }
            #expect(captured.needsFirstMark == [waiting.uuid])
            #expect(!context.hasChanges)
            try ItemOperations.archive(waiting, on: now, context: context)
            #expect(captured.needsFirstMark == [waiting.uuid])
            #expect(ReviewOperations.identifiersSnapshot(for: items, timeZone: .gmt, now: now).needsFirstMark.isEmpty)
        }
    }
}
