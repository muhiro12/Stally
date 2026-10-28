import StallyLibrary
import SwiftData
import SwiftUI

struct LibrarySidebar: View {
    let items: [Item]
    let tags: [Tag]
    @Binding var selection: LibraryDestination?
    let manageTags: () -> Void

    var body: some View {
        List(selection: $selection) {
            Section("Collection") {
                ForEach(LibraryDestination.collections, id: \.self) { destination in
                    NavigationLink(value: destination) {
                        Label {
                            Text(destination.title)
                        } icon: {
                            Image(systemName: destination.symbol)
                        }
                        .badge(
                            items.count { item in
                                destination.includes(item)
                            })
                    }
                }
            }
            Section {
                ForEach(tags) { tag in
                    NavigationLink(value: LibraryDestination.tag(tag.persistentModelID)) {
                        Label {
                            TagNameView(tag: tag, tags: tags)
                        } icon: {
                            Image(systemName: "tag")
                        }
                        .badge((tag.items ?? []).count)
                    }
                }
                Button("Manage Tags", systemImage: "tag", action: manageTags)
            } header: {
                Text("Tags")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Stally")
        .navigationSplitViewColumnWidth(
            min: LibraryLayout.sidebarMinimum,
            ideal: LibraryLayout.sidebarIdeal,
            max: LibraryLayout.sidebarMaximum)
    }
}
