//
//  ContentView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHAppRuntime
import SwiftData
import SwiftUI

struct ContentView: View {
    private enum StallyTab: Hashable {
        case library
        case review
        case insights
        case archive
        case backup
    }

    private enum PresentedSheet: Identifiable {
        case addItem
        case settings
        case item(Item)

        var id: String {
            switch self {
            case .addItem:
                "add-item"
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

    @State private var selectedTab: StallyTab
    @State private var presentedSheet: PresentedSheet?
    @State private var isPresentingMissingItemLinkAlert = false

    #if DEBUG
    @State private var pendingInitialPreviewRoute: StallyPreviewRoute?
    #endif

    private var activeItems: [Item] {
        ItemOperations.activeItems(from: items)
    }

    private var archivedItems: [Item] {
        ItemOperations.archivedItems(from: items)
    }

    private var reviewSnapshot: ReviewSnapshot {
        ReviewOperations.snapshot(for: items)
    }

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
        TabView(selection: $selectedTab) {
            LibraryView(
                items: activeItems,
                addAction: presentAddItem,
                settingsAction: presentSettings
            )
            .tabItem {
                Label("Library", systemImage: "tray")
            }
            .tag(StallyTab.library)

            ReviewView(snapshot: reviewSnapshot)
                .tabItem {
                    Label("Review", systemImage: "text.badge.checkmark")
                }
                .tag(StallyTab.review)

            InsightsView(items: items)
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(StallyTab.insights)

            ArchiveView(items: archivedItems)
                .tabItem {
                    Label("Archive", systemImage: "archivebox")
                }
                .tag(StallyTab.archive)

            BackupCenterView(items: items)
                .tabItem {
                    Label("Backup", systemImage: "externaldrive")
                }
                .tag(StallyTab.backup)
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .addItem:
                AddItemView()
            case .settings:
                SettingsView()
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
        #if DEBUG
        .task(id: items.count) {
            applyInitialPreviewRouteIfNeeded()
        }
        #endif
    }

    #if DEBUG
    init() {
        _selectedTab = .init(initialValue: .library)
        _pendingInitialPreviewRoute = .init(initialValue: nil)
    }

    init(initialPreviewRoute: StallyPreviewRoute) {
        _selectedTab = .init(initialValue: Self.tab(for: initialPreviewRoute))
        _pendingInitialPreviewRoute = .init(initialValue: initialPreviewRoute)
    }
    #else
    init() {
        _selectedTab = .init(initialValue: .library)
    }
    #endif

    #if DEBUG
    private static func tab(for route: StallyPreviewRoute?) -> StallyTab {
        switch route {
        case .archive:
            .archive
        case .backup:
            .backup
        case .insights:
            .insights
        case .review:
            .review
        case .addItem, .itemDetail, .library, .settings, nil:
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
            selectedTab = .library
        case .archive:
            selectedTab = .archive
        case .review:
            selectedTab = .review
        case .insights:
            selectedTab = .insights
        case .backupCenter:
            selectedTab = .backup
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

        selectedTab = item.isArchived ? .archive : .library
        presentedSheet = .item(item)
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
        case .itemDetail:
            guard let item = activeItems.first ?? items.first else {
                return
            }

            presentedSheet = .item(item)
            self.pendingInitialPreviewRoute = nil
        case .settings:
            presentedSheet = .settings
            self.pendingInitialPreviewRoute = nil
        case .archive, .backup, .insights, .library, .review:
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
