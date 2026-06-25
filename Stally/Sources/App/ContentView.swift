//
//  ContentView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

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

    @State private var selectedTab: StallyTab = .library
    @State private var presentedSheet: PresentedSheet?
    @State private var isPresentingUnsupportedLinkAlert = false

    private var activeItems: [Item] {
        ItemOperations.activeItems(from: items)
    }

    private var archivedItems: [Item] {
        ItemOperations.archivedItems(from: items)
    }

    private var reviewSnapshot: ReviewSnapshot {
        ReviewOperations.snapshot(for: items)
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
        .alert("Unsupported Link", isPresented: $isPresentingUnsupportedLinkAlert) {
            Button("OK", role: .cancel) {
                isPresentingUnsupportedLinkAlert = false
            }
        } message: {
            Text("This link is not supported by this version of Stally.")
        }
        .onOpenURL(perform: openLink)
    }

    private func presentAddItem() {
        presentedSheet = .addItem
    }

    private func presentSettings() {
        presentedSheet = .settings
    }

    private func openLink(_ url: URL) {
        switch StallyLinkOperations.parse(url) {
        case .supported(let link):
            openSupportedLink(link)
        case .unsupported:
            showUnsupportedLinkAlert()
        }
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
            showUnsupportedLinkAlert()
            return
        }

        selectedTab = item.isArchived ? .archive : .library
        presentedSheet = .item(item)
    }

    private func showUnsupportedLinkAlert() {
        isPresentingUnsupportedLinkAlert = true
    }
}

#Preview {
    ContentView()
        .modelContainer(ContentView.previewModelContainer)
}

private extension ContentView {
    static var previewModelContainer: ModelContainer {
        do {
            return try StallyModelContainerFactory.inMemory()
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }
}
