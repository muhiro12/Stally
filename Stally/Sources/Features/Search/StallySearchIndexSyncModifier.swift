import SwiftData
import SwiftUI

struct StallySearchIndexSyncModifier: ViewModifier {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(StallySearchIndexCoordinator.self)
    private var searchIndex
    @Query private var items: [Item]

    func body(content: Content) -> some View {
        let entries = ItemSearchIndexOperations.entries(for: items)
        content
            .task {
                await searchIndex.refresh(force: true)
            }
            .task(id: entries) {
                await searchIndex.refresh(force: false)
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    Task {
                        await searchIndex.refresh(force: true)
                    }
                }
            }
    }
}
