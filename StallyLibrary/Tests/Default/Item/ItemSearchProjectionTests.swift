import Foundation
import StallyLibrary
import Testing

extension SwiftDataOperationsTests {
    @Suite
    @MainActor
    struct ItemSearchProjectionTests {
        @Test
        func `live projection captures archive and edits without exposing private context`() throws {
            let container = try StallyModelContainerFactory.inMemory()
            defer {
                withExtendedLifetime(container) {
                    // Retain the in-memory store through the last assertion.
                }
            }
            let context = container.mainContext
            let first = try ItemOperations.create(
                context: context,
                input: .init(name: "Same", category: .other, note: "private")
            )
            let second = try ItemOperations.create(context: context, input: .init(name: "Same", category: .bags))
            let before = ItemSearchIndexOperations.entries(for: [first, second])
            try ItemOperations.archive(second, on: .now, context: context)
            try ItemOperations.update(
                first,
                input: .init(name: "Edited", category: .shoes, note: "private"),
                context: context
            )
            let after = ItemSearchIndexOperations.entries(for: try ItemOperations.items(context: context))
            #expect(before.allSatisfy { !$0.isArchived })
            #expect(after.first { $0.uuid == second.uuid }?.isArchived == true)
            #expect(after.first { $0.uuid == first.uuid }?.name == "Edited")
            #expect(before.first { $0.uuid == first.uuid }?.name == "Same")
            let encoded = try #require(String(data: JSONEncoder().encode(after), encoding: .utf8))
            #expect(!encoded.contains("private"))
            #expect(Set(after.map(\.uuid)) == [first.uuid, second.uuid])
        }

        @Test
        func `deleted source identity cannot be resolved to an equal name`() throws {
            let container = try StallyModelContainerFactory.inMemory()
            defer {
                withExtendedLifetime(container) {
                    // Retain the in-memory store through the last assertion.
                }
            }
            let context = container.mainContext
            let first = try ItemOperations.create(context: context, input: .init(name: "Same", category: .other))
            let second = try ItemOperations.create(context: context, input: .init(name: "Same", category: .other))
            let removedID = first.uuid
            try ItemOperations.delete(first, context: context)
            #expect(try ItemOperations.item(context: context, uuid: removedID) == nil)
            let entries = ItemSearchIndexOperations.entries(for: try ItemOperations.items(context: context))
            #expect(entries.map(\.uuid) == [second.uuid])
        }

        @Test
        func `replace import reconciles removed and restored search identities`() throws {
            let container = try StallyModelContainerFactory.inMemory()
            let incoming = try StallyModelContainerFactory.inMemory()
            defer {
                withExtendedLifetime((container, incoming)) {
                    // Both synthetic stores must outlive the import assertions.
                }
            }
            let context = container.mainContext
            let old = try ItemOperations.create(context: context, input: .init(name: "Old", category: .other))
            let oldID = old.uuid
            let restored = try ItemOperations.create(
                context: incoming.mainContext,
                input: .init(name: "Restored", category: .bags)
            )
            try ItemOperations.archive(restored, on: .now, context: incoming.mainContext)
            let data = try BackupOperations.exportData(for: [restored])
            let review = BackupOperations.review(data: data, currentItems: [old], replacingExistingItems: true)
            _ = try BackupOperations.importReviewed(review, context: context)
            let entries = ItemSearchIndexOperations.entries(for: try ItemOperations.items(context: context))
            #expect(entries.map(\.uuid) == [restored.uuid])
            #expect(entries.first?.isArchived == true)
            #expect(ItemSearchIndexOperations.removedIdentifiers(previous: [oldID], current: entries) == [oldID])
        }
    }
}
