//
//  ItemLibraryList.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHPlatform
import MHUI
import SwiftUI

struct ItemLibraryList: View {
    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @Environment(\.timeZone)
    private var timeZone
    @Environment(\.stallyReadingDate)
    private var readingDate

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    @State private var selectedFilter = ItemCollectionFilter.all
    @State private var selectedSort = ItemCollectionSort.defaultOrder
    @State private var selectedDate: Date?

    let items: [Item]
    let kind: ItemCollectionKind

    private var isRefined: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedCategory != nil
            || selectedFilter != .all
            || selectedSort != .defaultOrder
    }

    private var selectedDateBinding: Binding<Date> {
        .init {
            selectedDate ?? readingDate
        } set: { date in
            selectedDate = date
        }
    }

    var body: some View {
        let today = LocalDay(containing: readingDate, in: timeZone)
        let selectedDay = LocalDay(containing: selectedDate ?? readingDate, in: timeZone)
        let refinedItems = ItemCollectionOperations.items(
            from: items,
            options: .init(
                searchText: searchText,
                category: selectedCategory,
                filter: selectedFilter,
                sort: selectedSort
            ),
            today: today,
            selectedDay: selectedDay
        )

        List {
            listContent(refinedItems: refinedItems)
        }
        .stallyListChrome(.content)
        .searchable(
            text: $searchText,
            prompt: Text(kind.searchPrompt)
        )
    }

    @ViewBuilder
    private func listContent(refinedItems: [Item]) -> some View {
        ItemCollectionRefinementSection(
            kind: kind,
            shownItemCount: refinedItems.count,
            selectedCategory: $selectedCategory,
            selectedFilter: $selectedFilter,
            selectedSort: $selectedSort,
            selectedDate: selectedDateBinding
        )

        if refinedItems.isEmpty {
            Section {
                ContentUnavailableView {
                    Label(kind.noMatchesTitle, systemImage: "magnifyingglass")
                } actions: {
                    if isRefined {
                        Button("Clear", action: clearRefinements)
                    }
                }
                .mhRow()
            }
        } else {
            Section {
                ForEach(refinedItems) { item in
                    NavigationLink(value: StallyNavigationView.DetailRoute.item(item.uuid)) {
                        ItemRow()
                            .environment(item)
                    }
                    .mhRow()
                }
            }
        }

        if !isSubscribeOn {
            StallyAdvertisementSection(layout: .compact)
        }
    }

    private func clearRefinements() {
        searchText = ""
        selectedCategory = nil
        selectedFilter = .all
        selectedSort = .defaultOrder
        selectedDate = nil
    }
}
