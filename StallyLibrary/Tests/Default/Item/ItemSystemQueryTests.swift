import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemSystemQueryTests {
        @Test
        func `batch lookup resolves archived and non Mark identities only`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let first = try ItemOperations.create(context: context, input: .init(name: "First", category: .other))
            let second = try ItemOperations.create(context: context, input: .init(name: "Second", category: .bags))
            let unrelated = try ItemOperations.create(context: context, input: .init(name: "Other", category: .other))
            first.recordsMarks = false
            try ItemOperations.archive(second, on: .now, context: context)

            let found = try ItemOperations.items(context: context, uuids: [first.uuid, second.uuid, .init()])
            #expect(Set(found.map(\.uuid)) == Set([first.uuid, second.uuid]))
            #expect(!found.contains { $0.uuid == unrelated.uuid })
            #expect(try ItemOperations.items(context: context, uuids: []).isEmpty)
        }

        @Test
        func `suggestions are bounded active readings and include pending changes`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            context.autosaveEnabled = false
            let older = try ItemOperations.create(
                context: context,
                input: .init(name: "Older", category: .other),
                createdAt: .init(timeIntervalSinceReferenceDate: 1)
            )
            let newer = try ItemOperations.create(
                context: context,
                input: .init(name: "Newer", category: .other),
                createdAt: .init(timeIntervalSinceReferenceDate: 2)
            )
            let pending = Item(
                name: "Pending",
                category: .other,
                note: "",
                createdAt: .init(timeIntervalSinceReferenceDate: 3),
                uuid: .init(),
                photoData: nil,
                archivedAt: nil
            )
            pending.recordsMarks = false
            context.insert(pending)
            newer.archivedAt = .now

            #expect(try ItemOperations.suggestedItems(context: context, limit: 1).map(\.uuid) == [pending.uuid])
            let suggestions = try ItemOperations.suggestedItems(context: context, limit: 2)
            #expect(suggestions.map(\.uuid) == [pending.uuid, older.uuid])
            #expect(try ItemOperations.suggestedItems(context: context, limit: 0).isEmpty)
            #expect(try ItemOperations.suggestedItems(context: context, limit: -1).isEmpty)
            #expect(try ItemOperations.items(context: context, uuids: [pending.uuid]).first?.uuid == pending.uuid)
            context.rollback()
        }
    }
}
