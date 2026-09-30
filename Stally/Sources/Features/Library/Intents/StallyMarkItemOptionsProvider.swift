import AppIntents
import SwiftData

/// Limits Mark action suggestions while generic item queries keep resolving every UUID.
struct StallyMarkItemOptionsProvider: DynamicOptionsProvider {
    private static let suggestionLimit = 40

    @Dependency private var modelContainer: ModelContainer

    func results() async throws -> [StallyItemEntity] {
        try await MainActor.run {
            let items = try ItemOperations.suggestedItems(
                context: modelContainer.mainContext,
                limit: Self.suggestionLimit
            )
            return StallyItemEntity.make(from: ItemOperations.itemsEligibleForHistoryChanges(from: items))
        }
    }
}
