import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct NonMarkReadingTests {
        @Test
        func `non Mark records never enter Review or stale bulk actions`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            let zone = try #require(TimeZone(secondsFromGMT: 0))
            let now = try #require(today.date(in: zone))
            let first = try createItem(context: context)
            let dormant = try createItem(context: context)
            let recovery = try createItem(context: context)
            let oldDay = try #require(today.adding(days: -100))
            for item in [dormant, recovery] {
                try ItemOperations.mark(item, on: oldDay, today: today, context: context)
            }
            try ItemOperations.archive(recovery, on: now, context: context)
            for item in [first, dormant, recovery] {
                item.recordsMarks = false
            }
            try context.save()
            let snapshot = ReviewOperations.snapshot(for: [first, dormant, recovery], timeZone: zone, now: now)
            #expect(snapshot.needsFirstMark.isEmpty)
            #expect(snapshot.dormant.isEmpty)
            #expect(snapshot.recoveryCandidates.isEmpty)
            let changed = try ReviewOperations.performPrimaryActions([
                .init(item: first, lane: .needsFirstMark),
                .init(item: dormant, lane: .dormant),
                .init(item: recovery, lane: .recoveryCandidates)
            ],
            context: context,
            on: now
            )
            #expect(changed == 0)
            #expect(!first.isArchived)
            #expect(!dormant.isArchived)
            #expect(recovery.isArchived)
            let eligible = try createItem(context: context)
            #expect(try ReviewOperations.performPrimaryActions([
                .init(item: first, lane: .needsFirstMark),
                .init(item: eligible, lane: .needsFirstMark),
                .init(item: eligible, lane: .needsFirstMark)
            ],
            context: context,
            on: now
            ) == 1)
        }

        @Test(arguments: [false, true])
        func `non Mark items change context coverage but not any choice reading`(_ includesArchive: Bool) throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            let zone = try #require(TimeZone(secondsFromGMT: 0))
            let now = try #require(today.date(in: zone))
            let start = try #require(ItemStart(rawValue: "2000"))
            let marked = try createItem(context: context)
            try ItemOperations.mark(marked, on: today, today: today, context: context)
            let nonMark = try ItemOperations.create(
                context: context,
                input: .init(
                    name: "Plant", category: .other, note: "Growing", photoData: try TestPhotoFixtures.preparedData()
                ),
                tracking: .init(recordsMarks: false, start: start),
                today: today
            )
            let options = InsightsOptions(range: .allTime, includesArchivedItems: includesArchive)
            let before = InsightsOperations.snapshot(for: [marked], options: options, timeZone: zone, now: now)
            let after = InsightsOperations.snapshot(for: [marked, nonMark], options: options, timeZone: zone, now: now)
            #expect(after.choiceItemCount == before.choiceItemCount)
            #expect(after.totalMarks == before.totalMarks)
            #expect(after.activeDays == before.activeDays)
            #expect(after.uniqueMarkedItems == before.uniqueMarkedItems)
            #expect(after.uniqueMarkedCategories == before.uniqueMarkedCategories)
            #expect(after.currentStreak == before.currentStreak)
            #expect(after.bestStreak == before.bestStreak)
            #expect(after.topItems.map(\.item.uuid) == before.topItems.map(\.item.uuid))
            #expect(after.quietItems.map(\.item.uuid) == before.quietItems.map(\.item.uuid))
            #expect(after.categoryShares == before.categoryShares)
            #expect(after.weekdayActivity == before.weekdayActivity)
            #expect(after.monthlyActivity == before.monthlyActivity)
            #expect(after.recommendations.map(\.kind) == before.recommendations.map(\.kind))
            #expect(after.noteCoverage == .init(coveredCount: 1, totalCount: 2))
            #expect(after.photoCoverage == .init(coveredCount: 1, totalCount: 2))
            try ItemOperations.archive(nonMark, on: now, context: context)
            let archived = InsightsOperations.snapshot(
                for: [marked, nonMark], options: options, timeZone: zone, now: now
            )
            #expect(archived.noteCoverage.totalCount == (includesArchive ? 2 : 1))
            #expect(archived.totalMarks == before.totalMarks)
        }

        @Test
        func `empty choice scopes have no Mark recommendation and flag inconsistent history`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let item = try createItem(context: context)
            item.recordsMarks = false
            item.startRawValue = "invalid"
            try context.save()
            let empty = InsightsOperations.snapshot(for: [item])
            #expect(empty.choiceItemCount == 0)
            #expect(empty.recommendations.isEmpty)
            #expect(empty.nonMarkHistoryConflictCount == 0)
            #expect(InsightsReportOperations.report(for: empty, locale: .init(identifier: "en"))
                        .contains("No items in this scope record Marks."))
            let day = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            let mark = ItemMark(day: day, createdAt: .now, item: item, uuid: .init())
            item.marks.append(mark)
            context.insert(mark)
            try context.save()
            let conflict = InsightsOperations.snapshot(for: [item])
            #expect(conflict.totalMarks == 0)
            #expect(conflict.nonMarkHistoryConflictCount == 1)
            #expect(InsightsReportOperations.report(for: conflict, locale: .init(identifier: "en"))
                        .contains("Choice readings are incomplete."))
        }

        @Test
        func `unavailable dates preserve collection scope and localized conflict reporting`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let choice = try createItem(context: context)
            let nonMark = try createItem(context: context)
            let day = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            try ItemOperations.mark(nonMark, on: day, today: day, context: context)
            nonMark.recordsMarks = false
            nonMark.note = "Retained context"
            try context.save()
            let zone = try #require(TimeZone(secondsFromGMT: 0))
            let outsideSupportedYears = Date(timeIntervalSince1970: 253_402_300_800)
            #expect(LocalDay(containing: outsideSupportedYears, in: zone) == nil)
            let snapshot = InsightsOperations.snapshot(
                for: [choice, nonMark], timeZone: zone, now: outsideSupportedYears
            )
            #expect(snapshot.choiceItemCount == 1)
            #expect(snapshot.nonMarkHistoryConflictCount == 1)
            #expect(snapshot.noteCoverage == .init(coveredCount: 1, totalCount: 2))
            #expect(snapshot.totalMarks == 0)
            #expect(snapshot.recommendations.isEmpty)
            #expect(InsightsReportOperations.report(for: snapshot, locale: .init(identifier: "en"))
                        .contains("Choice readings are incomplete."))
            #expect(InsightsReportOperations.report(for: snapshot, locale: .init(identifier: "ja"))
                        .contains("選択の集計が不完全です。"))
            #expect(nonMark.marks.count == 1)
        }

        private func createItem(context: ModelContext) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(name: "Bag", category: .bags),
                createdAt: .init(timeIntervalSince1970: 0)
            )
        }
    }
}
