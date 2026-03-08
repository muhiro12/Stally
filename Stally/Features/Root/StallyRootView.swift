//
//  StallyRootView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

import MHPlatform
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyRootView: View {
    private enum Route: Hashable {
        case archive
        case backup
        case item(UUID)
        case review
        case settings
    }

    private enum EditorMode: Hashable {
        case create
        case edit(UUID)
    }

    private struct EditorRoute: Identifiable {
        let mode: EditorMode

        var id: String {
            switch mode {
            case .create:
                "create"
            case .edit(let itemID):
                "edit-\(itemID.uuidString)"
            }
        }
    }

    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(\.modelContext)
    private var context
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(MHObservableDeepLinkInbox.self)
    private var deepLinkInbox

    @Query(
        sort: [
            SortDescriptor(\Item.createdAt, order: .reverse)
        ]
    )
    private var items: [Item]

    @State private var path: [Route] = []
    @State private var editorRoute: EditorRoute?
    @State private var operationErrorMessage: String?
    @State private var reviewPreferences = StallyReviewPreferences()
    @State private var hasLoadedReviewPreferences = false

    var body: some View {
        NavigationStack(path: $path) {
            StallyHomeView(
                items: activeItems,
                reviewPreferences: reviewPreferences,
                reviewSummary: reviewSummary,
                archiveSummary: ItemInsightsCalculator.archiveSummary(
                    from: archivedItems
                ),
                onOpenItem: { itemID in
                    path.append(.item(itemID))
                },
                onCreateItem: {
                    editorRoute = .init(mode: .create)
                },
                onSeedSampleData: seedSampleData,
                onOpenArchive: {
                    path.append(.archive)
                },
                onOpenReview: {
                    path.append(.review)
                },
                onOpenSettings: {
                    path.append(.settings)
                },
                onToggleTodayMark: toggleTodayMark(for:)
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .archive:
                    StallyArchiveView(items: archivedItems) { itemID in
                        path.append(.item(itemID))
                    }
                case .backup:
                    StallyBackupCenterView(items: items)
                case .review:
                    StallyReviewView(
                        items: items,
                        preferences: reviewPreferences,
                        onArchiveItem: archiveItem(_:),
                        onArchiveItems: archiveItems(_:),
                        onUnarchiveItem: unarchiveItem(_:),
                        onUnarchiveItems: unarchiveItems(_:),
                        onOpenItem: { itemID in
                            path.append(.item(itemID))
                        }
                    )
                case .settings:
                    StallySettingsView(
                        reviewPreferences: $reviewPreferences,
                        onOpenBackup: {
                            path.append(.backup)
                        }
                    )
                case .item(let itemID):
                    destinationView(for: itemID)
                }
            }
        }
        .alert(
            "Unable to Complete This Action",
            isPresented: isOperationErrorPresented
        ) {
            Button("OK", role: .cancel) {
                operationErrorMessage = nil
            }
        } message: {
            Text(operationErrorMessage ?? "")
        }
        .sheet(item: $editorRoute) { route in
            editorDestination(for: route)
        }
        .task {
            appRuntime.startIfNeeded()
            loadReviewPreferencesIfNeeded()
        }
        .task(id: deepLinkInbox.pendingURL) {
            await applyPendingDeepLinkIfNeeded()
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else {
                return
            }

            appRuntime.startIfNeeded()
        }
        .onOpenURL { url in
            Task {
                await deepLinkInbox.ingest(url)
            }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard let webpageURL = userActivity.webpageURL else {
                return
            }

            Task {
                await deepLinkInbox.ingest(webpageURL)
            }
        }
        .onChange(of: reviewPreferences) { _, newValue in
            newValue.save(in: appRuntime.preferenceStore)
        }
    }
}

private extension StallyRootView {
    var deepLinkCodec: MHDeepLinkCodec<StallyRoute> {
        StallyDeepLinking.codec()
    }

    var activeItems: [Item] {
        ItemInsightsCalculator.homeSort(
            items: ItemInsightsCalculator.activeItems(from: items)
        )
    }

    var archivedItems: [Item] {
        ItemInsightsCalculator.archivedItems(from: items)
    }

    var reviewSummary: ItemReviewSummary {
        ItemReviewCalculator.summary(
            from: items,
            policy: reviewPreferences.policy
        )
    }

    var isOperationErrorPresented: Binding<Bool> {
        .init(
            get: {
                operationErrorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    operationErrorMessage = nil
                }
            }
        )
    }

    func item(for itemID: UUID) -> Item? {
        items.first { item in
            item.id == itemID
        }
    }

    @ViewBuilder
    private func destinationView(
        for itemID: UUID
    ) -> some View {
        if let item = item(for: itemID) {
            StallyItemDetailView(
                item: item,
                onEdit: { editableItemID in
                    editorRoute = .init(mode: .edit(editableItemID))
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
                removeItemRoute(itemID)
            }
        }
    }

    @ViewBuilder
    private func editorDestination(
        for route: EditorRoute
    ) -> some View {
        NavigationStack {
            switch route.mode {
            case .create:
                StallyItemEditorView(mode: .create) { createdItemID in
                    editorRoute = nil

                    if let createdItemID {
                        path.append(.item(createdItemID))
                    }
                } onDelete: { _ in
                    // no-op
                }
            case .edit(let itemID):
                if let item = item(for: itemID) {
                    StallyItemEditorView(mode: .edit(item)) { _ in
                        editorRoute = nil
                    } onDelete: { deletedItemID in
                        editorRoute = nil
                        removeItemRoute(deletedItemID)
                    }
                } else {
                    Color.clear
                        .task {
                            editorRoute = nil
                        }
                }
            }
        }
    }

    private func removeItemRoute(
        _ itemID: UUID
    ) {
        path.removeAll { route in
            if case .item(let pathItemID) = route {
                return pathItemID == itemID
            }

            return false
        }
    }

    private func toggleTodayMark(
        for item: Item
    ) {
        do {
            _ = try MarkService.toggle(
                context: context,
                item: item
            )
        } catch {
            presentOperationError(error)
        }
    }

    private func toggleArchiveState(
        for item: Item
    ) {
        do {
            if item.isArchived {
                try ItemService.unarchive(
                    context: context,
                    item: item
                )
            } else {
                try ItemService.archive(
                    context: context,
                    item: item
                )
            }
        } catch {
            presentOperationError(error)
        }
    }

    private func archiveItem(
        _ item: Item
    ) {
        guard !item.isArchived else {
            return
        }

        do {
            try ItemService.archive(
                context: context,
                item: item
            )
        } catch {
            presentOperationError(error)
        }
    }

    private func archiveItems(
        _ items: [Item]
    ) {
        guard !items.isEmpty else {
            return
        }

        do {
            try ItemService.archive(
                context: context,
                items: items
            )
        } catch {
            presentOperationError(error)
        }
    }

    private func unarchiveItem(
        _ item: Item
    ) {
        guard item.isArchived else {
            return
        }

        do {
            try ItemService.unarchive(
                context: context,
                item: item
            )
        } catch {
            presentOperationError(error)
        }
    }

    private func unarchiveItems(
        _ items: [Item]
    ) {
        guard !items.isEmpty else {
            return
        }

        do {
            try ItemService.unarchive(
                context: context,
                items: items
            )
        } catch {
            presentOperationError(error)
        }
    }

    private func setMarkState(
        for item: Item,
        on date: Date,
        shouldBeMarked: Bool
    ) -> Bool {
        do {
            if shouldBeMarked {
                _ = try MarkService.mark(
                    context: context,
                    item: item,
                    on: date
                )
            } else {
                _ = try MarkService.unmark(
                    context: context,
                    item: item,
                    on: date
                )
            }

            return true
        } catch {
            presentOperationError(error)
            return false
        }
    }

    private func seedSampleData() {
        do {
            try ItemService.seedSampleData(
                context: context,
                ifEmptyOnly: true
            )
        } catch {
            presentOperationError(error)
        }
    }

    private func presentOperationError(
        _ error: any Error
    ) {
        operationErrorMessage = (error as? LocalizedError)?.errorDescription
            ?? "Please try again."
    }

    private func loadReviewPreferencesIfNeeded() {
        guard hasLoadedReviewPreferences == false else {
            return
        }

        reviewPreferences = StallyReviewPreferences.load(
            from: appRuntime.preferenceStore
        )
        hasLoadedReviewPreferences = true
    }

    @MainActor
    private func applyPendingDeepLinkIfNeeded() async {
        guard let pendingURL = deepLinkInbox.pendingURL else {
            return
        }

        guard let route = deepLinkCodec.parse(pendingURL) else {
            _ = await deepLinkInbox.consumeLatestURL()
            operationErrorMessage = "This link isn't supported by this version of Stally."
            return
        }

        switch route {
        case .home:
            _ = await deepLinkInbox.consumeLatest(using: deepLinkCodec)
            editorRoute = nil
            path.removeAll()
        case .archive:
            _ = await deepLinkInbox.consumeLatest(using: deepLinkCodec)
            editorRoute = nil
            path = [.archive]
        case .backup:
            _ = await deepLinkInbox.consumeLatest(using: deepLinkCodec)
            editorRoute = nil
            path = [.backup]
        case .review:
            _ = await deepLinkInbox.consumeLatest(using: deepLinkCodec)
            editorRoute = nil
            path = [.review]
        case .settings:
            _ = await deepLinkInbox.consumeLatest(using: deepLinkCodec)
            editorRoute = nil
            path = [.settings]
        case .item(let itemID):
            _ = await deepLinkInbox.consumeLatest(using: deepLinkCodec)
            editorRoute = nil
            path = itemPath(for: itemID)
        case .createItem:
            _ = await deepLinkInbox.consumeLatest(using: deepLinkCodec)
            path.removeAll()
            editorRoute = .init(mode: .create)
        }
    }

    private func itemPath(
        for itemID: UUID
    ) -> [Route] {
        guard let item = item(for: itemID) else {
            return [.item(itemID)]
        }

        if item.isArchived {
            return [
                .archive,
                .item(itemID)
            ]
        }

        return [.item(itemID)]
    }
}
