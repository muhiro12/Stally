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
    @Binding var selection: PersistentIdentifier?
    @Binding var searchText: String
    let addItem: () -> Void
    @State private var sortOrder = SortOrder.newest

    private var visibleItems: [Item] {
        let matching = items.filter { item in
            searchText.isEmpty || item.name.localizedStandardContains(searchText)
                || item.note.localizedStandardContains(searchText)
                || (item.tags ?? []).contains { tag in
                    tag.name.localizedStandardContains(searchText)
                }
        }
        return matching.sorted { first, second in
            switch sortOrder {
            case .newest:
                first.createdAt > second.createdAt
            case .oldest:
                first.createdAt < second.createdAt
            case .name:
                first.name.localizedStandardCompare(second.name) == .orderedAscending
            }
        }
    }

    var body: some View {
        let displayedItems = visibleItems
        List(selection: $selection) {
            ForEach(displayedItems) { item in
                NavigationLink(value: item.persistentModelID) {
                    ItemListRow(item: item)
                }
            }
        }
        .overlay {
            if displayedItems.isEmpty {
                if !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ContentUnavailableView {
                        Label("No Items Here", systemImage: "square.stack")
                    } description: {
                        Text("Keep a record of something that matters to you.")
                    } actions: {
                        Button("Add Item", systemImage: "plus", action: addItem)
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
        .searchable(text: $searchText, prompt: "Search names, notes, and tags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Item", systemImage: "plus", action: addItem)
                    .keyboardShortcut("n", modifiers: .command)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu("Sort Items", systemImage: "arrow.up.arrow.down") {
                    Picker("Sort Items", selection: $sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                }
            }
            ToolbarItem(placement: .status) {
                Text("\(displayedItems.count) Items").foregroundStyle(.secondary)
            }
        }
    }
}
