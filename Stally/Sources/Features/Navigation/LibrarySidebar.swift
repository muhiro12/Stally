import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct LibrarySidebar: View {
    @Environment(\.modelContext)
    private var context
    @State private var showingDiagnostics = false

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
                Button("Debug", systemImage: "ladybug") {
                    showingDiagnostics = true
                }
            }
        }
        .mhListChrome(.native)
        .listStyle(.sidebar)
        .navigationTitle("Stally")
        .navigationSplitViewColumnWidth(
            min: LibraryLayout.sidebarMinimum,
            ideal: LibraryLayout.sidebarIdeal,
            max: LibraryLayout.sidebarMaximum
        )
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView(container: context.container, startupError: nil)
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
