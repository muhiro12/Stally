import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct RecordWriteSessionTests {
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
