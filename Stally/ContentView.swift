//
//  ContentView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [TrackedItem]

    @State private var isPresentingAddSheet = false

    private var sortedItems: [TrackedItem] {
        items.sorted(by: compareItems)
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isPresentingAddSheet = true
                        } label: {
                            Label("対象を追加", systemImage: "plus")
                        }
                    }
                }
                .navigationTitle("Stally")
                .sheet(isPresented: $isPresentingAddSheet) {
                    AddItemView()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if sortedItems.isEmpty {
            emptyStateView
        } else {
            itemListView
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("まだ対象がありません", systemImage: "square.stack")
        } description: {
            Text("数えたい対象を追加すると、ここに積み上がりが並びます。")
        } actions: {
            Button("対象を追加") {
                isPresentingAddSheet = true
            }
        }
    }

    private var itemListView: some View {
        List {
            ForEach(sortedItems) { item in
                itemRow(for: item)
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for offset in offsets {
                modelContext.delete(sortedItems[offset])
            }

            try? modelContext.save()
        }
    }

    private func compareItems(lhs: TrackedItem, rhs: TrackedItem) -> Bool {
        switch (lhs.lastCountedAt, rhs.lastCountedAt) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
            return lhsDate > rhsDate
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            break
        }

        if lhs.totalCount != rhs.totalCount {
            return lhs.totalCount > rhs.totalCount
        }

        return lhs.createdAt > rhs.createdAt
    }

    private func itemRow(for item: TrackedItem) -> some View {
        NavigationLink {
            ItemDetailView(item: item)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(item.name)
                        .font(.body.weight(.medium))

                    Spacer(minLength: 12)

                    Text("\(item.totalCount) 回")
                        .font(.headline)
                        .monospacedDigit()
                }

                Text("最終記録 \(item.lastCountedAtText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
    }
}
