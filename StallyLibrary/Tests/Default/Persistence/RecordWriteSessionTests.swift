import Foundation
import MHPlatformCore
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct RecordWriteSessionTests {
    @Test(arguments: [false, true])
    func subscriptionChangesPreservePendingReviewAndDraft(isICloudOn: Bool) async throws {
        let suiteName = "RecordWriteSessionTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let store = MHPreferenceStore(userDefaults: defaults)
        store.set(isICloudOn, for: \.stallyICloudEnabled)
        ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Before")
        var draft = ItemOperations.draft(for: item)
        draft.name = "After"
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        try ItemOperations.create(context: source, name: "Imported")
        let archive = try TransferOperations.export(context: source, includingImages: false)
        let review = try TransferOperations.review(archive, context: context)
        let session = RecordWriteSession(updates: .init())

        ICloudSyncOperations.updateSubscriptionAccess(.inactive, store: store)
        #expect(!ICloudSyncOperations.isEnabled(store: store))
        try session.checkCurrent()
        ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
        #expect(ICloudSyncOperations.isEnabled(store: store) == isICloudOn)
        store.set(false, for: \.stallyICloudEnabled)
        #expect(!ICloudSyncOperations.isEnabled(store: store))
        try session.checkCurrent()
        #expect(context.container === container)
        #expect(!context.hasChanges)
        #expect(item.name == "Before" && draft.name == "After")

        try await session.performMutation {
            try TransferOperations.apply(
                review, selection: review.defaultSelection, today: "2026-11-14", context: context
            )
        }
        try await session.performMutation {
            try ItemOperations.save(draft, context: context)
        }
        let saved = try ModelContext(container).fetch(FetchDescriptor<Item>())
        #expect(Set(saved.map(\.name)) == ["After", "Imported"])
        #expect(saved.first { $0.uuid == item.uuid }?.name == "After")
    }

    @Test
    func accountChangeRejectsAnOtherwiseValidReviewAndDraft() async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        try ItemOperations.create(context: source, name: "From file")
        let archive = try TransferOperations.export(context: source, includingImages: false)
        let review = try TransferOperations.review(archive, context: context)
        let oldSession = RecordWriteSession(updates: .init())
        oldSession.invalidate()

        await #expect(throws: RecordSessionError.accountChanged) {
            try await oldSession.performMutation {
                try TransferOperations.apply(
                    review, selection: review.defaultSelection, today: "2026-11-02", context: context
                )
            }
        }
        await #expect(throws: RecordSessionError.accountChanged) {
            try await oldSession.performMutation { _ = try ItemOperations.create(context: context, name: "Old draft") }
        }
        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 0)

        let currentSession = RecordWriteSession(updates: .init())
        try await currentSession.performMutation { _ = try ItemOperations.create(context: context, name: "New draft") }
        #expect(try context.fetch(FetchDescriptor<Item>()).map(\.name) == ["New draft"])
    }
}
