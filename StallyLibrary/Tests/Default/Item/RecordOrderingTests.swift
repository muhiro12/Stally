import Foundation
import Testing

@testable import StallyLibrary

@MainActor
struct RecordOrderingTests {
    @Test(arguments: [false, true])
    func marksUseOccurrenceThenRegistrationThenIdentity(reversed: Bool) throws {
        let item = Item(name: "Camera", note: "")
        let day = ItemMark(item: item, localDateTime: "2026-11-10")
        let minute = ItemMark(item: item, localDateTime: "2026-11-10T12:30")
        let earlierRegistration = ItemMark(item: item, localDateTime: "2026-11-10")
        let sameRegistration = ItemMark(item: item, localDateTime: "2026-11-10")
        day.createdAt = Date(timeIntervalSince1970: 200)
        minute.createdAt = Date(timeIntervalSince1970: 100)
        earlierRegistration.createdAt = Date(timeIntervalSince1970: 100)
        sameRegistration.createdAt = day.createdAt
        day.uuid = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        sameRegistration.uuid = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let records = [earlierRegistration, sameRegistration, minute, day]
        item.marks = reversed ? Array(records.reversed()) : records
        let originalIDs = item.marks?.map(\.uuid)

        #expect(MarkOperations.orderedMarks(for: item).map(\.uuid)
                    == [minute.uuid, day.uuid, sameRegistration.uuid, earlierRegistration.uuid])
        #expect(item.marks?.map(\.uuid) == originalIDs)

        minute.localDateTime = "2026-11-09T12:30"
        #expect(MarkOperations.orderedMarks(for: item).last?.uuid == minute.uuid)
    }

    @Test(arguments: [false, true])
    func periodsUseRegistrationWithoutInventingDatePrecision(reversed: Bool) throws {
        let item = Item(name: "Home", note: "")
        let recent = ItemPeriod(item: item, startLocalDate: nil, endLocalDate: nil, isOngoing: false)
        let sameRegistration = ItemPeriod(item: item, startLocalDate: "2020", endLocalDate: nil, isOngoing: true)
        let older = ItemPeriod(item: item, startLocalDate: "2025-01", endLocalDate: "2025-02", isOngoing: false)
        recent.createdAt = Date(timeIntervalSince1970: 200)
        sameRegistration.createdAt = recent.createdAt
        older.createdAt = Date(timeIntervalSince1970: 100)
        recent.uuid = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        sameRegistration.uuid = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let records = [older, sameRegistration, recent]
        item.periods = reversed ? Array(records.reversed()) : records
        let originalIDs = item.periods?.map(\.uuid)

        #expect(PeriodOperations.orderedPeriods(for: item).map(\.uuid)
                    == [recent.uuid, sameRegistration.uuid, older.uuid])
        #expect(item.periods?.map(\.uuid) == originalIDs)
        #expect(recent.startLocalDate == nil && recent.endLocalDate == nil && !recent.isOngoing)
        #expect(sameRegistration.startLocalDate == "2020" && sameRegistration.isOngoing)
    }

    @Test(arguments: [false, true])
    func tagsUseNaturalNameOrderAndRetainEqualNames(reversed: Bool) throws {
        let item = Item(name: "Camera", note: "")
        let first = Tag(name: "Tag 2")
        let sameName = Tag(name: "Tag 2")
        let last = Tag(name: "Tag 10")
        first.uuid = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        sameName.uuid = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let records = [last, sameName, first]
        item.tags = reversed ? Array(records.reversed()) : records
        let originalIDs = item.tags?.map(\.uuid)

        #expect(TagOperations.orderedTags(for: item).map(\.uuid) == [first.uuid, sameName.uuid, last.uuid])
        #expect(item.tags?.map(\.uuid) == originalIDs)
    }

    @Test
    func absentRelationshipsReturnEmptyCollections() {
        let item = Item(name: "New", note: "")
        item.marks = nil
        item.periods = nil
        item.tags = nil

        #expect(MarkOperations.orderedMarks(for: item).isEmpty)
        #expect(PeriodOperations.orderedPeriods(for: item).isEmpty)
        #expect(TagOperations.orderedTags(for: item).isEmpty)
    }
}
