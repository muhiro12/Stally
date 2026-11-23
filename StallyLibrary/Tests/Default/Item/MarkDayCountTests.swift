import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct MarkDayCountTests {
    @Test
    func countsUseTheRecordedDayAndFollowCorrectionsAndUndo() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Notebook")
        let firstDay = "2026-10-31"
        let lastDay = "2026-11-01"
        let range = firstDay...lastDay
        try MarkOperations.add(to: item, localDateTime: "2026-10-30", context: context)
        try MarkOperations.add(to: item, localDateTime: "2026-10-31T23:59", context: context)
        let added = try MarkOperations.add(to: item, localDateTime: firstDay, context: context)
        #expect(MarkOperations.countsByDay(for: item, in: range) == [firstDay: 2])
        try MarkOperations.correct(added, localDateTime: lastDay, context: context)
        #expect(MarkOperations.countsByDay(for: item, in: range) == [firstDay: 1, lastDay: 1])
        try MarkOperations.undoAddition(uuid: added.uuid, context: context)
        #expect(MarkOperations.countsByDay(for: item, in: range) == [firstDay: 1])
    }
}
