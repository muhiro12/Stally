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
    private enum PresentedSheet: Identifiable {
        case addItem
        case backupCenter
        case settings
        case item(Item)

        var id: String {
            switch self {
            case .addItem:
                "add-item"
            case .backupCenter:
                "backup-center"
            case .settings:
                "settings"
            case .item(let item):
                "item-\(item.uuid)"
            }
        }
    }

    @Query(sort: \Item.createdAt, order: .reverse)
    private var items: [Item]
    @Environment(StallyRouteInbox.self)
    private var routeInbox
    @Environment(StallyRoutePipeline.self)
    private var routePipeline
    @Environment(\.timeZone)
    private var timeZone
    @AppStorage(\.needsFirstMarkAfterDays)
    private var needsFirstMarkAfterDays
    @AppStorage(\.dormantAfterDays)
    private var dormantAfterDays

    @State private var selectedDestination: StallyNavigationView.Destination?
    @State private var preferredCompactColumn: NavigationSplitViewColumn
    @State private var presentedSheet: PresentedSheet?
    @State private var isPresentingMissingItemLinkAlert = false

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

    var body: some View {
        let now = Date()
        let reviewSnapshot = ReviewOperations.snapshot(
            for: items,
            settings: .init(
                needsFirstMarkAfterDays: needsFirstMarkAfterDays,
                dormantAfterDays: dormantAfterDays
            ),
            timeZone: timeZone,
            now: now
        )

        StallyNavigationView(
            selectedDestination: $selectedDestination,
            preferredCompactColumn: $preferredCompactColumn,
            items: items,
            reviewSnapshot: reviewSnapshot,
            allowsSampleItems: items.isEmpty,
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
                    BackupCenterView(items: items)
                }
            case .settings:
                SettingsView(items: items)
            case .item(let item):
                NavigationStack {
                    ItemDetailView(item: item)
                }
            }
        }
        .alert("Unsupported Link", isPresented: $isPresentingMissingItemLinkAlert) {
            Button("OK", role: .cancel) {
                isPresentingMissingItemLinkAlert = false
            }
        } message: {
            Text("This link is not supported by this version of Stally.")
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
        #if DEBUG
        .task(id: items.count) {
            applyInitialPreviewRouteIfNeeded()
        }
        #endif
    }

    #if DEBUG
    init() {
        _selectedDestination = .init(initialValue: .library)
        _preferredCompactColumn = .init(initialValue: .detail)
        _pendingInitialPreviewRoute = .init(initialValue: nil)
    }

    init(initialPreviewRoute: StallyPreviewRoute) {
        _selectedDestination = .init(
            initialValue: Self.navigationDestination(for: initialPreviewRoute)
        )
        _preferredCompactColumn = .init(initialValue: .detail)
        _pendingInitialPreviewRoute = .init(initialValue: initialPreviewRoute)
    }
    #else
    init() {
        _selectedDestination = .init(initialValue: .library)
        _preferredCompactColumn = .init(initialValue: .detail)
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
            presentedSheet = .backupCenter
        case .createItem:
            presentedSheet = .addItem
        case .settings:
            presentedSheet = .settings
        }
    }

    private func openItemLink(_ itemID: UUID) {
        guard let item = items.first(where: { item in
            item.uuid == itemID
        }) else {
            showMissingItemLinkAlert()
            return
        }

        selectNavigationDestination(item.isArchived ? .archive : .library)
        presentedSheet = .item(item)
    }

    private func selectNavigationDestination(
        _ destination: StallyNavigationView.Destination
    ) {
        selectedDestination = destination
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
            let activeItems = ItemOperations.activeItems(from: items)
            guard let item = activeItems.first(where: { $0.photoData != nil })
                    ?? activeItems.first
                    ?? items.first else {
                return
            }

            presentedSheet = .item(item)
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
