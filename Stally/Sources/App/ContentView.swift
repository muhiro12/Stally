//
//  ContentView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \Item.createdAt, order: .reverse)
    private var items: [Item]

    @State private var isPresentingAddItem = false

    private var activeItems: [Item] {
        ItemOperations.activeItems(from: items)
    }

    private var archivedItems: [Item] {
        ItemOperations.archivedItems(from: items)
    }

    var body: some View {
        TabView {
            LibraryView(items: activeItems, addAction: presentAddItem)
                .tabItem {
                    Label("Library", systemImage: "tray")
                }

            ArchiveView(items: archivedItems)
                .tabItem {
                    Label("Archive", systemImage: "archivebox")
                }
        }
        .sheet(isPresented: $isPresentingAddItem) {
            AddItemView()
        }
    }

    private func presentAddItem() {
        isPresentingAddItem = true
    }
}

#Preview {
    ContentView()
        .modelContainer(ContentView.previewModelContainer)
}

private extension ContentView {
    static var previewModelContainer: ModelContainer {
        do {
            return try StallyModelContainerFactory.inMemory()
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }
}
