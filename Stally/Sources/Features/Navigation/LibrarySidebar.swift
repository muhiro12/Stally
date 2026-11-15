import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct LibrarySidebar: View {
    @State private var showingSettings = false

    let items: [Item]
    let tags: [Tag]
    @Binding var selection: LibraryDestination?
    let manageTags: () -> Void
    let transfer: () -> Void

    var body: some View {
        List(selection: $selection) {
            collectionSection
            tagSection
            Section {
                Button("Import & Export", systemImage: "arrow.up.arrow.down.square", action: transfer)
                Button("Settings", systemImage: "gearshape") {
                    showingSettings = true
                }
            }
        }
        .mhListChrome(.native, background: .native)
        .listStyle(.sidebar)
        .navigationTitle("Stally")
        .sheet(isPresented: $showingSettings) {
            StallySettingsView()
        }
    }

    private var collectionSection: some View {
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
                            destination.includes(item) && item.isArchived == (destination == .archive)
                        }
                    )
                }
            }
        }
    }

    private var tagSection: some View {
        Section {
            ForEach(tags) { tag in
                NavigationLink(value: LibraryDestination.tag(tag.persistentModelID)) {
                    Label {
                        TagNameView(tag: tag, tags: tags)
                    } icon: {
                        Image(systemName: "tag")
                    }
                    .badge((tag.items ?? []).filter { !$0.isArchived }.count)
                }
            }
            Button("Manage Tags", systemImage: "tag", action: manageTags)
        } header: {
            Text("Tags")
        }
    }
}
