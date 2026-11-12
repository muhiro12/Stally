import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct ItemListView: View {
    private enum SortOrder: String, CaseIterable, Identifiable {
        case newest
        case oldest
        case name

        var id: Self {
            self
        }
        var title: LocalizedStringResource {
            switch self {
            case .newest:
                "Newest First"
            case .oldest:
                "Oldest First"
            case .name:
                "Name"
            }
        }
    }

    let items: [Item]
    let title: String
    let initialScope: ItemQuery.ArchiveScope
    @Binding var selection: PersistentIdentifier?
    @Binding var searchText: String
    @Binding var archiveScope: ItemQuery.ArchiveScope
    let addItem: () -> Void
    @State private var sortOrder = SortOrder.newest

    private var visibleItems: [Item] {
        var query = ItemQuery()
        query.text = searchText
        query.archiveScope = archiveScope
        query.order = ItemQuery.Order(rawValue: sortOrder.rawValue) ?? .newest
        return query.matching(items)
    }

    var body: some View {
        let displayedItems = visibleItems
        List(selection: $selection) {
            MHContainerContent {
                ForEach(displayedItems) { item in
                    NavigationLink(value: item.persistentModelID) {
                        ItemListRow()
                            .environment(item)
                    }
                    .draggable(StallyLinkOperations.url(for: .item(item.uuid)))
                }
            }
        }
        .mhListChrome(.content)
        .overlay {
            if displayedItems.isEmpty {
                if !searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Matching Items", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try another search or reset the filters for this collection.")
                    } actions: {
                        Button("Reset Filters", action: resetFilters)
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Items Here", systemImage: "square.stack")
                    } description: {
                        Text("Keep a record of something that matters to you.")
                    } actions: {
                        if archiveScope != initialScope {
                            Button("Reset Filters", action: resetFilters)
                        }
                        StallyActionButton(.addItem, action: addItem)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationSplitViewColumnWidth(
            min: LibraryLayout.listMinimum,
            ideal: LibraryLayout.listIdeal,
            max: LibraryLayout.listMaximum
        )
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search names, notes, and tags"
        )
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .toolbar {
            ToolbarItem(placement: LibraryLayout.primaryActionPlacement) {
                StallyActionButton(.addItem, action: addItem)
                    .keyboardShortcut("n", modifiers: .command)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu("Filter and Sort", systemImage: "line.3.horizontal.decrease") {
                    Picker("Include", selection: $archiveScope) {
                        Text("Library").tag(ItemQuery.ArchiveScope.library)
                        Text("Archive").tag(ItemQuery.ArchiveScope.archived)
                        Text("All Items").tag(ItemQuery.ArchiveScope.all)
                    }
                    Picker("Sort Items", selection: $sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                }
            }
            ToolbarItem(placement: .status) {
                Text("\(displayedItems.count) Items").mhForegroundStyle(.secondaryText)
            }
        }
    }

    private func resetFilters() {
        searchText = ""
        archiveScope = initialScope
    }
}
