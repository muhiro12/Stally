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
        .modelContainer(for: [Item.self, ItemMark.self], inMemory: true)
}
