//
//  ContentView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHPlatform
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(StallyRouteInbox.self)
    private var routeInbox
    @Environment(StallyRoutePipeline.self)
    private var routePipeline

    @State private var selectedDestination: StallyNavigationView.Destination?
    @State private var preferredCompactColumn: NavigationSplitViewColumn
    @State private var detailPath: [StallyNavigationView.DetailRoute]
    @State private var presentedSheet: ContentViewPresentedSheet?
    @State private var isPresentingMissingItemLinkAlert = false
    @State private var itemResolutionError: String?

    #if DEBUG
    @State private var pendingInitialPreviewRoute: StallyPreviewRoute?
    #endif

    private var invalidDeepLinkAlertBinding: Binding<Bool> {
        .init(
            get: {
                routePipeline.lastParseFailureURL != nil
            },
            set: { isPresented in
                if !isPresented {
                    routePipeline.clearLastParseFailure()
                }
            }
        )
    }

    private var navigationDestinationBinding: Binding<StallyNavigationView.Destination?> {
        .init(
            get: {
                selectedDestination
            },
            set: { destination in
                guard destination != selectedDestination else {
                    return
                }

                selectedDestination = destination
                detailPath.removeAll()

                if destination != nil {
                    preferredCompactColumn = .detail
                }
            }
        )
    }

    var body: some View {
        StallyNavigationView(
            selectedDestination: navigationDestinationBinding,
            preferredCompactColumn: $preferredCompactColumn,
            detailPath: $detailPath,
            addAction: presentAddItem,
            restoreAction: presentBackupCenter,
            settingsAction: presentSettings
        )
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .addItem:
                AddItemView()
            case .backupCenter:
                NavigationStack {
                    BackupCenterView()
                }
            case .settings:
                SettingsView()
            }
        }
        .alert("Unsupported Link", isPresented: $isPresentingMissingItemLinkAlert) {
            Button("OK", role: .cancel) {
                isPresentingMissingItemLinkAlert = false
            }
        } message: {
            Text("This link is not supported by this version of Stally.")
        }
        .alert("Stally", isPresented: isShowingItemResolutionError) {
            Button("OK", role: .cancel) {
                itemResolutionError = nil
            }
        } message: {
            Text(itemResolutionError ?? "")
        }
        .alert(
            "Unsupported Link",
            isPresented: invalidDeepLinkAlertBinding,
            presenting: routePipeline.lastParseFailureURL
        ) { _ in
            Button("OK", role: .cancel) {
                routePipeline.clearLastParseFailure()
            }
        } message: { _ in
            Text("This link is not supported by this version of Stally.")
        }
        .mhRouteHandler(routeInbox) { link in
            openSupportedLink(link)
        }
        .stallySubscriptionStateSync()
        .stallyTemporaryStorageAlert()
        #if DEBUG
        .task {
            applyInitialPreviewRouteIfNeeded()
        }
        #endif
    }

    #if DEBUG
    init() {
        _selectedDestination = .init(initialValue: .library)
        _preferredCompactColumn = .init(initialValue: .detail)
        _detailPath = .init(initialValue: [])
        _pendingInitialPreviewRoute = .init(initialValue: nil)
    }

    init(initialPreviewRoute: StallyPreviewRoute) {
        _selectedDestination = .init(
            initialValue: Self.navigationDestination(for: initialPreviewRoute)
        )
        _preferredCompactColumn = .init(initialValue: .detail)
        _detailPath = .init(initialValue: [])
        _pendingInitialPreviewRoute = .init(initialValue: initialPreviewRoute)
    }
    #else
    init() {
        _selectedDestination = .init(initialValue: .library)
        _preferredCompactColumn = .init(initialValue: .detail)
        _detailPath = .init(initialValue: [])
    }
    #endif

    #if DEBUG
    private static func navigationDestination(
        for route: StallyPreviewRoute?
    ) -> StallyNavigationView.Destination {
        switch route {
        case .archive:
            .archive
        case .insights:
            .insights
        case .review:
            .review
        case .addItem, .backup, .itemDetail, .library, .settings, nil:
            .library
        }
    }
    #endif

    private func presentAddItem() {
        presentedSheet = .addItem
    }

    private func presentSettings() {
        presentedSheet = .settings
    }

    private func presentBackupCenter() {
        presentedSheet = .backupCenter
    }

    private func openSupportedLink(_ link: StallyLink) {
        switch link {
        case .destination(let destination):
            openDestination(destination)
        case .item(let itemID):
            openItemLink(itemID)
        }
    }

    private func openDestination(_ destination: StallyLinkDestination) {
        switch destination {
        case .library:
            selectNavigationDestination(.library)
        case .archive:
            selectNavigationDestination(.archive)
        case .review:
            selectNavigationDestination(.review)
        case .insights:
            selectNavigationDestination(.insights)
        case .backupCenter:
            presentBackupCenter()
        case .createItem:
            presentAddItem()
        case .settings:
            presentSettings()
        }
    }

    private func openItemLink(_ itemID: UUID) {
        do {
            guard let item = try ItemOperations.item(context: modelContext, uuid: itemID) else {
                showMissingItemLinkAlert()
                return
            }
            selectNavigationDestination(item.isArchived ? .archive : .library)
            detailPath = [.item(item.uuid)]
        } catch {
            itemResolutionError = error.localizedDescription
        }
    }

    private func selectNavigationDestination(
        _ destination: StallyNavigationView.Destination
    ) {
        presentedSheet = nil
        selectedDestination = destination
        detailPath.removeAll()
        preferredCompactColumn = .detail
    }

    private func showMissingItemLinkAlert() {
        isPresentingMissingItemLinkAlert = true
    }

    #if DEBUG
    private func applyInitialPreviewRouteIfNeeded() {
        guard let pendingInitialPreviewRoute else {
            return
        }

        switch pendingInitialPreviewRoute {
        case .addItem:
            presentedSheet = .addItem
            self.pendingInitialPreviewRoute = nil
        case .backup:
            presentedSheet = .backupCenter
            self.pendingInitialPreviewRoute = nil
        case .itemDetail:
            guard let items = try? ItemOperations.items(context: modelContext) else {
                return
            }
            let activeItems = ItemOperations.activeItems(from: items)
            guard let item = activeItems.first(where: { $0.photoData != nil })
                    ?? activeItems.first
                    ?? items.first else {
                return
            }

            selectNavigationDestination(item.isArchived ? .archive : .library)
            detailPath = [.item(item.uuid)]
            self.pendingInitialPreviewRoute = nil
        case .settings:
            presentedSheet = .settings
            self.pendingInitialPreviewRoute = nil
        case .archive, .insights, .library, .review:
            self.pendingInitialPreviewRoute = nil
        }
    }
    #endif
}

private extension ContentView {
    var isShowingItemResolutionError: Binding<Bool> {
        .init {
            itemResolutionError != nil
        } set: { isPresented in
            if !isPresented {
                itemResolutionError = nil
            }
        }
    }
}

#if DEBUG
#Preview("Stally - Empty Library") {
    StallyPreviewContainer(.empty) { _ in
        ContentView()
    }
}

#Preview("Stally - Typical Collection") {
    StallyPreviewContainer(.typical) { _ in
        ContentView()
    }
}
#endif
