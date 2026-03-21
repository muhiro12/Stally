import StallyLibrary
import SwiftUI

@MainActor
extension StallyRootView {
    var librarySnapshot: StallyLibrarySnapshot {
        StallyLibrarySnapshotBuilder.build(
            items: items,
            reviewPreferences: appModel.reviewPreferences
        )
    }

    var archiveSnapshot: StallyArchiveSnapshot {
        StallyArchiveSnapshotBuilder.build(
            items: items
        )
    }

    var reviewSnapshot: StallyReviewSnapshot {
        StallyReviewSnapshotBuilder.build(
            items: items,
            preferences: appModel.reviewPreferences
        )
    }

    var insightsSnapshot: StallyInsightsSnapshot {
        StallyInsightsSnapshotBuilder.build(
            items: items,
            preferences: appModel.insightsPreferences
        )
    }

    var settingsSnapshot: StallySettingsSnapshot {
        StallySettingsSnapshotBuilder.build()
    }

    var isOperationErrorPresented: Binding<Bool> {
        .init(
            get: {
                appModel.operationErrorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    appModel.dismissOperationError()
                }
            }
        )
    }

    func stackHost<Content: View>(
        path: Binding<[StallyAppModel.StackDestination]>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        NavigationStack(path: path) {
            content()
                .navigationDestination(
                    for: StallyAppModel.StackDestination.self
                ) { destination in
                    destinationView(for: destination)
                }
        }
    }

    @ViewBuilder
    func destinationView(
        for destination: StallyAppModel.StackDestination
    ) -> some View {
        switch destination {
        case .item(let itemID):
            if let item = items.first(where: { $0.id == itemID }) {
                StallyItemDetailView(
                    item: item,
                    navigationNamespace: navigationNamespace
                )
            } else {
                ContentUnavailableView(
                    "Item Unavailable",
                    systemImage: "questionmark.square.dashed",
                    description: Text("This item no longer exists.")
                )
                .task {
                    appModel.removeItemDestination(itemID)
                }
            }
        case .settings:
            StallySettingsView(
                snapshot: settingsSnapshot
            )
        case .backup:
            StallyBackupCenterView(
                items: items
            )
        }
    }

    @ViewBuilder
    func editorDestination(
        for route: StallyAppModel.EditorRoute
    ) -> some View {
        NavigationStack {
            switch route.mode {
            case .create:
                StallyItemEditorView(
                    mode: .create,
                    navigationNamespace: navigationNamespace
                )
                .navigationTransition(
                    .zoom(
                        sourceID: "create-item",
                        in: navigationNamespace
                    )
                )
            case .edit(let itemID):
                if let item = items.first(where: { $0.id == itemID }) {
                    StallyItemEditorView(
                        mode: .edit(item),
                        navigationNamespace: navigationNamespace
                    )
                } else {
                    Color.clear
                        .task {
                            appModel.dismissEditor()
                        }
                }
            }
        }
    }

    func applyRoute(
        _ route: StallyRoute
    ) {
        StallyAppRouteService.apply(
            route: route,
            to: appModel,
            items: items
        )
    }
}
