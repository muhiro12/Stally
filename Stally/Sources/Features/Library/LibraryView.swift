import StallyLibrary
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Query(sort: \Item.createdAt, order: .reverse)
    private var items: [Item]
    @Query(sort: \Tag.name)
    private var tags: [Tag]
    @State private var destination: LibraryDestination? = .library
    @State private var selectedItemID: PersistentIdentifier?
    @State private var compactColumn = NavigationSplitViewColumn.content
    @State private var addingItem = false
    @State private var managingTags = false
    @State private var routeError: String?

    private var selectedItem: Item? {
        items.first { item in
            item.persistentModelID == selectedItemID
        }
    }

    private var title: String {
        if case .tag(let identifier) = destination,
           let tag = tags.first(where: { tag in
            tag.persistentModelID == identifier
           }) {
            return tag.name
        }
        return String(localized: (destination ?? .library).title)
    }

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            LibrarySidebar(items: items, tags: tags, selection: $destination) {
                managingTags = true
            }
        } content: {
            ItemListView(
                items: items.filter { item in
                    (destination ?? .library).includes(item)
                },
                title: title,
                selection: $selectedItemID
            ) {
                addingItem = true
            }
        } detail: {
            if let selectedItem {
                ItemDetailView(item: selectedItem) {
                    selectedItemID = nil
                    compactColumn = .content
                }
                .id(selectedItem.persistentModelID)
            } else {
                ContentUnavailableView {
                    Label("Choose an Item", systemImage: "square.stack")
                } description: {
                    Text("Your Marks, periods, and notes will appear here.")
                } actions: {
                    Button("Add Item", systemImage: "plus") {
                        addingItem = true
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $addingItem) {
            ItemEditor(item: nil) { item in
                destination = .library
                selectedItemID = item.persistentModelID
                compactColumn = .detail
            }
        }
        .sheet(isPresented: $managingTags) {
            TagManagerView()
        }
        .onChange(of: destination) { _, _ in
            if let selectedItem, !(destination ?? .library).includes(selectedItem) {
                selectedItemID = nil
            }
        }
        .onChange(of: tags.map(\.persistentModelID)) { _, identifiers in
            if case .tag(let identifier) = destination, !identifiers.contains(identifier) {
                destination = .library
            }
        }
        .onOpenURL(perform: openLink)
        .alert("Could not open link", isPresented: showingRouteError) {
            Button("OK") {
                routeError = nil
            }
        } message: {
            Text(routeError ?? "")
        }
    }

    private var showingRouteError: Binding<Bool> {
        .init(
            get: {
                routeError != nil
            },
            set: { isPresented in
                if !isPresented {
                    routeError = nil
                }
            })
    }

    private func openLink(_ url: URL) {
        guard case .supported(.item(let uuid)) = StallyLinkOperations.parse(url) else {
            routeError = String(localized: "This destination is not available yet.")
            return
        }
        let matches = items.filter { item in
            item.uuid == uuid
        }
        guard matches.count == 1, let item = matches.first else {
            routeError = String(localized: "The linked Item is missing or has a conflicting identity.")
            return
        }
        destination = item.isArchived ? .archive : .library
        selectedItemID = item.persistentModelID
        compactColumn = .detail
    }
}
