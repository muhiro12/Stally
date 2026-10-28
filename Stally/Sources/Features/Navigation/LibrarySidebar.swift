import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct LibrarySidebar: View {
    #if DEBUG
    @Environment(\.modelContext)
    private var context
    @State private var showingDevelopment = false
    #endif

    let items: [Item]
    let tags: [Tag]
    @Binding var selection: LibraryDestination?
    let manageTags: () -> Void

    var body: some View {
        List(selection: $selection) {
            collectionSection
            tagSection
            #if DEBUG
            Section {
                Button("Developer Tools", systemImage: "hammer") {
                    showingDevelopment = true
                }
            }
            #endif
        }
        .mhListChrome(.native)
        .listStyle(.sidebar)
        .navigationTitle("Stally")
        .navigationSplitViewColumnWidth(
            min: LibraryLayout.sidebarMinimum,
            ideal: LibraryLayout.sidebarIdeal,
            max: LibraryLayout.sidebarMaximum)
        #if DEBUG
        .sheet(isPresented: $showingDevelopment) {
            DevelopmentView(container: context.container, startupError: nil)
        }
        #endif
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
                            destination.includes(item)
                        })
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
                    .badge((tag.items ?? []).count)
                }
            }
            Button("Manage Tags", systemImage: "tag", action: manageTags)
        } header: {
            Text("Tags")
        }
    }
}
