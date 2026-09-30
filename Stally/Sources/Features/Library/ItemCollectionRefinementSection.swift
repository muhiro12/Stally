//
//  ItemCollectionRefinementSection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import MHUI
import SwiftUI

struct ItemCollectionRefinementSection: View {
    @Environment(\.stallyReadingDate)
    private var readingDate

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
                .listRowSeparator(.hidden, edges: .top)

            if selectedFilter == .openOnDay || selectedFilter == .markedOnDay {
                DatePicker(
                    "Day",
                    selection: $selectedDate,
                    in: ...readingDate,
                    displayedComponents: .date
                )
                .mhRow()
            }
        } footer: {
            if selectedSort == .earliestStart || selectedSort == .latestStart {
                Text("Partial dates are ordered by their earliest possible day. Unknown starts appear last.")
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
                    .mhForegroundStyle(.secondaryText)
            }
            .mhTextStyle(.bodyStrong, colorRole: .primaryText)
        }
    }
}
