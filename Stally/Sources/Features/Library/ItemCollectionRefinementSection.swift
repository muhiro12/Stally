//
//  ItemCollectionRefinementSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import MHUI
import SwiftUI

struct ItemCollectionRefinementSection: View {
    let kind: ItemCollectionKind
    let shownItemCount: Int

    @Binding var selectedCategory: ItemCategory?
    @Binding var selectedFilter: ItemCollectionFilter
    @Binding var selectedSort: ItemCollectionSort
    @Binding var selectedDate: Date

    var body: some View {
        Section {
            refinementMenu
                .mhRow()

            if selectedFilter == .openOnDay || selectedFilter == .markedOnDay {
                DatePicker(
                    "Day",
                    selection: $selectedDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .mhRow()
            }
        }
    }

    private var refinementMenu: some View {
        Menu {
            Picker("Category", selection: $selectedCategory) {
                Text("All Categories")
                    .tag(nil as ItemCategory?)

                ForEach(ItemCategory.allCases) { category in
                    Text(category.title)
                        .tag(category as ItemCategory?)
                }
            }

            Picker("Filter", selection: $selectedFilter) {
                ForEach(kind.availableFilters) { filter in
                    Text(filter.title)
                        .tag(filter)
                }
            }

            Picker("Sort", selection: $selectedSort) {
                ForEach(ItemCollectionSort.allCases) { sort in
                    Text(sort.title)
                        .tag(sort)
                }
            }
        } label: {
            HStack {
                Label("Refine", systemImage: "line.3.horizontal.decrease.circle")

                Spacer()

                Text(shownItemCount, format: .number)
                    .foregroundStyle(.secondary)
            }
            .mhTextStyle(.bodyStrong, colorRole: .primaryText)
        }
    }
}
