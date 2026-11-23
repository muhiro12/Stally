import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct ItemListView: View {
    let items: [Item]
    let showsLibraryActivity: Bool
    let title: String
    let initialScope: ItemQuery.ArchiveScope
    @Binding var selection: PersistentIdentifier?
    @Binding var searchText: String
    @Binding var archiveScope: ItemQuery.ArchiveScope
    let addItem: () -> Void
    @State private var selectedMarkDay: MarkDayDetail.Selection?
    @State private var sortOrder = ItemListSortOrder.newest

    private var visibleItems: [Item] {
        var query = ItemQuery()
        query.text = searchText
        query.archiveScope = archiveScope
        return sortOrder.matching(items, query: query)
    }

    var body: some View {
        let displayedItems = visibleItems
        let showsActivity = showsLibraryActivity && !items.isEmpty && searchText.isEmpty && archiveScope == .library
        List(selection: $selection) {
            MHContainerContent {
                if showsActivity {
                    MarkActivitySection(items: items) { day in
                        selectedMarkDay = .init(day: day)
                    }
                    if displayedItems.isEmpty {
                        emptyState
                    }
                }
                ForEach(displayedItems) { item in
                    HStack {
                        NavigationLink(value: item.persistentModelID) {
                            ItemListRow()
                        }
                        .draggable(StallyLinkOperations.url(for: .item(item.uuid)))
                        if item.isMarkRecordingEnabled {
                            QuickMarkButtons(inList: true)
                        }
                    }
                    .environment(item)
                    .tag(item.persistentModelID)
                }
            }
        }
        .mhListChrome(.content)
        .overlay {
            if displayedItems.isEmpty, !showsActivity {
                emptyState
            }
        }
        .navigationTitle(title)
        .sheet(item: $selectedMarkDay) { selection in
            MarkDayDetail(day: selection.day, items: items)
        }
        .searchable(
            text: $searchText,
            prompt: "Search names, notes, and tags"
        )
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
                        ForEach(ItemListSortOrder.allCases, id: \.self) { order in
                            Text(order.title).tag(order)
                        }
                    }
                }
            }
            ToolbarItem(placement: .status) {
                Text("\(displayedItems.count) Items")
                    .mhForegroundStyle(.secondaryText)
                    .padding()
            }
        }
    }

    @ViewBuilder private var emptyState: some View {
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

    private func resetFilters() {
        searchText = ""
        archiveScope = initialScope
    }
}
