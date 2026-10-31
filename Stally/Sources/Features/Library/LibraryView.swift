import StallyLibrary
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(TransferPresentation.self)
    private var transferPresentation
    @Query(sort: \Item.createdAt, order: .reverse)
    private var items: [Item]
    @Query(sort: \Tag.name)
    private var tags: [Tag]
    @State private var destination: LibraryDestination? = .library
    @State private var selectedItemID: PersistentIdentifier?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var compactColumn = NavigationSplitViewColumn.content
    @State private var searchText = ""
    @State private var addingItem = false
    @State private var managingTags = false
    @State private var transferring = false
    @State private var importURL: URL?
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
        @Bindable var presentation = transferPresentation
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $compactColumn
        ) {
            LibrarySidebar(
                items: items,
                tags: tags,
                selection: $destination,
                manageTags: { managingTags = true },
                transfer: {
                    importURL = nil
                    transferring = true
                }
            )
        } content: {
            ItemListView(
                items: items.filter { item in
                    (destination ?? .library).includes(item)
                },
                title: title,
                initialScope: destination == .archive ? .archived : .library,
                selection: $selectedItemID,
                searchText: $searchText
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
        .sheet(item: $presentation.review) { review in
            ImportReviewView(review: review) { _ in transferPresentation.review = nil }
        }
        .sheet(isPresented: $transferring) {
            TransferView(initialURL: importURL)
        }
        .sheet(isPresented: $addingItem) {
            ItemEditor(item: nil) { item in
                destination = .library
                searchText = ""
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
            }
        )
    }

    private func openLink(_ url: URL) {
        if url.isFileURL {
            importURL = url
            transferring = true
            return
        }
        if case .supported(.destination(let target)) = StallyLinkOperations.parse(url) {
            switch target {
            case .library:
                destination = .library
            case .archive:
                destination = .archive
            case .importExport:
                importURL = nil
                transferring = true
            case .createItem:
                addingItem = true
            }
            return
        }
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
        searchText = ""
        selectedItemID = item.persistentModelID
        compactColumn = .detail
    }
}
