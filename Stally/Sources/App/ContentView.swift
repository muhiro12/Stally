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

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyLibraryView(addAction: presentAddItem)
                } else {
                    ItemLibraryList(items: items)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: presentAddItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddItem) {
                AddItemView()
            }
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
