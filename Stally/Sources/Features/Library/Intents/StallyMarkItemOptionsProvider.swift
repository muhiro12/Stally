import AppIntents
import SwiftData

/// Limits Mark action suggestions while generic item queries keep resolving every UUID.
struct StallyMarkItemOptionsProvider: DynamicOptionsProvider {
    @Dependency private var modelContainer: ModelContainer

    func results() async throws -> [StallyItemEntity] {
        try await MainActor.run {
            let items = try ItemOperations.items(context: modelContainer.mainContext)
            return StallyItemEntity.make(from: ItemOperations.itemsEligibleForHistoryChanges(from: items))
        }
    }
}
