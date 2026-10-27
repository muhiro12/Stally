import StallyLibrary
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Query(sort: \Item.createdAt, order: .reverse)
    private var items: [Item]
    @State private var showingArchive = false
    @State private var addingItem = false
    @State private var path: [Item] = []
    @State private var routeError: String?

    var body: some View {
        NavigationStack(path: $path) {
            itemList
                .navigationTitle(showingArchive ? String(localized: "Archive") : String(localized: "Library"))
                .navigationDestination(for: Item.self) { item in
                    ItemDetailView(item: item)
                }
                .toolbar {
                    Button("Add Item", systemImage: "plus") { addingItem = true }
                }
                .sheet(isPresented: $addingItem) { ItemEditor(item: nil) }
                .onOpenURL(perform: openLink)
                .alert(
                    "Could not open link",
                    isPresented: Binding(
                        get: { routeError != nil },
                        set: { if !$0 { routeError = nil } }
                    )
                ) {
                    Button("OK") { routeError = nil }
                } message: {
                    Text(routeError ?? "")
                }
        }
    }
    private var itemList: some View {
        List {
            Toggle("Show Archive", isOn: $showingArchive)
            ForEach(items.filter { $0.isArchived == showingArchive }) { item in
                NavigationLink(value: item) {
                    HStack {
                        Text(item.name)
                        Spacer()
                        if item.isFavorite {
                            Image(systemName: "star.fill")
                                .accessibilityLabel("Favorite")
                        }
                    }
                }
            }
        }
    }

    private func openLink(_ url: URL) {
        guard case .supported(.item(let uuid)) = StallyLinkOperations.parse(url) else {
            routeError = String(localized: "This destination is not available yet.")
            return
        }
        let matches = items.filter { $0.uuid == uuid }
        guard matches.count == 1, let item = matches.first else {
            routeError = String(localized: "The linked Item is missing or has a conflicting identity.")
            return
        }
        path = [item]
    }
}
