import Foundation
import MHAppRuntime
import StallyLibrary
import SwiftUI

@MainActor
extension StallyRootView {
    @ViewBuilder
    func rootDestination(
        for route: StallyRootNavigationState.Route
    ) -> some View {
        switch route {
        case .archive:
            StallyArchiveView(items: archivedItems) { itemID in
                openItem(itemID)
            }
        case .backup:
            StallyBackupCenterView(
                items: items,
                onMergeImport: mergeImport(snapshot:),
                onReplaceImport: replaceImport(snapshot:),
                onDeleteAll: deleteAllItems
            )
        case .review:
            StallyReviewView(
                items: items,
                preferences: navigationState.reviewPreferences,
                onArchiveItem: archiveItem(_:),
                onArchiveItems: archiveItems(_:),
                onUnarchiveItem: unarchiveItem(_:),
                onUnarchiveItems: unarchiveItems(_:),
                onOpenItem: openItem(_:)
            )
        case .settings:
            StallySettingsView(
                reviewPreferences: $navigationState.reviewPreferences,
                onOpenBackup: openBackup
            )
        case .item(let itemID):
            destinationView(for: itemID)
        }
    }

    func item(
        for itemID: UUID
    ) -> Item? {
        items.first { item in
            item.id == itemID
        }
    }

    @ViewBuilder
    func destinationView(
        for itemID: UUID
    ) -> some View {
        if let item = item(for: itemID) {
            StallyItemDetailView(
                item: item,
                onEdit: { editableItemID in
                    navigationState.presentEditEditor(editableItemID)
                },
                onToggleTodayMark: toggleTodayMark(for:),
                onToggleArchiveState: toggleArchiveState(for:),
                onSetMarkState: setMarkState(for:on:shouldBeMarked:)
            )
        } else {
            ContentUnavailableView(
                "Item Unavailable",
                systemImage: "questionmark.square.dashed",
                description: Text("This item no longer exists.")
            )
            .task {
                navigationState.removeItemRoute(itemID)
            }
        }
    }

    @ViewBuilder
    func editorDestination(
        for route: StallyRootNavigationState.EditorRoute
    ) -> some View {
        NavigationStack {
            switch route.mode {
            case .create:
                StallyItemEditorView(mode: .create) { createdItemID in
                    navigationState.dismissEditor()

                    if let createdItemID {
                        openItem(createdItemID)
                    }
                } onDelete: { _ in
                    // no-op
                }
            case .edit(let itemID):
                if let item = item(for: itemID) {
                    StallyItemEditorView(mode: .edit(item)) { _ in
                        navigationState.dismissEditor()
                    } onDelete: { deletedItemID in
                        navigationState.dismissEditor()
                        navigationState.removeItemRoute(deletedItemID)
                    }
                } else {
                    Color.clear
                        .task {
                            navigationState.dismissEditor()
                        }
                }
            }
        }
    }

    func openItem(
        _ itemID: UUID
    ) {
        navigationState.path.append(
            StallyRootNavigationState.Route.item(itemID)
        )
    }

    func openCreateItem() {
        navigationState.presentCreateEditor()
    }

    func openArchive() {
        navigationState.path.append(
            StallyRootNavigationState.Route.archive
        )
    }

    func openBackup() {
        navigationState.path.append(
            StallyRootNavigationState.Route.backup
        )
    }

    func openReview() {
        navigationState.path.append(
            StallyRootNavigationState.Route.review
        )
    }

    func openSettings() {
        navigationState.path.append(
            StallyRootNavigationState.Route.settings
        )
    }

    func toggleTodayMark(
        for item: Item
    ) {
        performAction {
            try StallyRootActionService.toggleTodayMark(
                context: context,
                item: item
            )
        }
    }

    func toggleArchiveState(
        for item: Item
    ) {
        performAction {
            try StallyRootActionService.toggleArchiveState(
                context: context,
                item: item
            )
        }
    }

    func archiveItem(
        _ item: Item
    ) {
        performAction {
            try StallyRootActionService.archive(
                context: context,
                item: item
            )
        }
    }

    func archiveItems(
        _ items: [Item]
    ) {
        performAction {
            try StallyRootActionService.archive(
                context: context,
                items: items
            )
        }
    }

    func unarchiveItem(
        _ item: Item
    ) {
        performAction {
            try StallyRootActionService.unarchive(
                context: context,
                item: item
            )
        }
    }

    func unarchiveItems(
        _ items: [Item]
    ) {
        performAction {
            try StallyRootActionService.unarchive(
                context: context,
                items: items
            )
        }
    }

    func setMarkState(
        for item: Item,
        on date: Date,
        shouldBeMarked: Bool
    ) -> Bool {
        performBooleanAction {
            try StallyRootActionService.setMarkState(
                context: context,
                item: item,
                on: date,
                shouldBeMarked: shouldBeMarked
            )
        }
    }

    func seedSampleData() {
        performAction {
            try StallyRootActionService.seedSampleData(
                context: context
            )
        }
    }

    func mergeImport(
        snapshot: StallyBackupSnapshot
    ) throws -> StallyBackupImportResult {
        try StallyRootActionService.mergeImport(
            context: context,
            snapshot: snapshot
        )
    }

    func replaceImport(
        snapshot: StallyBackupSnapshot
    ) throws -> StallyBackupImportResult {
        try StallyRootActionService.replaceImport(
            context: context,
            snapshot: snapshot
        )
    }

    func deleteAllItems() throws {
        try StallyRootActionService.deleteAllItems(
            context: context
        )
    }

    func performAction(
        _ operation: () throws -> Void
    ) {
        do {
            try operation()
        } catch {
            navigationState.presentOperationError(error)
        }
    }

    func performBooleanAction(
        _ operation: () throws -> Bool
    ) -> Bool {
        do {
            return try operation()
        } catch {
            navigationState.presentOperationError(error)
            return false
        }
    }

    func loadReviewPreferencesIfNeeded() {
        navigationState.loadReviewPreferencesIfNeeded(
            from: appRuntime.preferenceStore
        )
    }

    func synchronizePendingRouteIfNeeded() async {
        switch await StallyRootRouteService.resolvePendingRoute(
            from: deepLinkInbox,
            codec: deepLinkCodec
        ) {
        case .none:
            return
        case .route(let route):
            StallyRootRouteService.apply(
                route: route,
                to: &navigationState,
                items: items
            )
        case .unsupported:
            navigationState.presentUnsupportedDeepLinkError()
        }
    }
}
