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
        case item(UUID)
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

    var body: some View {
        NavigationStack(path: $path) {
            StallyHomeView(
                items: activeItems,
                onOpenItem: { itemID in
                    path.append(.item(itemID))
                },
                onCreateItem: {
                    editorRoute = .init(mode: .create)
                },
                onOpenArchive: {
                    path.append(.archive)
                },
                onToggleTodayMark: toggleTodayMark(for:)
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .archive:
                    StallyArchiveView(items: archivedItems) { itemID in
                        path.append(.item(itemID))
                    }
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
    }
}

private extension StallyRootView {
    var activeItems: [Item] {
        ItemInsightsCalculator.homeSort(
            items: ItemInsightsCalculator.activeItems(from: items)
        )
    }

    var archivedItems: [Item] {
        ItemInsightsCalculator.archivedItems(from: items)
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
                onToggleArchiveState: toggleArchiveState(for:)
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

    private func presentOperationError(
        _ error: any Error
    ) {
        operationErrorMessage = (error as? LocalizedError)?.errorDescription
            ?? "Please try again."
    }
}
