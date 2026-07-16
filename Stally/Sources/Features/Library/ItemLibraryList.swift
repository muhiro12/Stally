//
//  ItemLibraryList.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHPlatform
import SwiftUI
import UIKit

struct ItemLibraryList: View {
    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @Environment(\.timeZone)
    private var timeZone
    @Environment(\.scenePhase)
    private var scenePhase

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    @State private var selectedFilter = ItemCollectionFilter.all
    @State private var selectedSort = ItemCollectionSort.defaultOrder
    @State private var selectedDate = Date.now
    @State private var currentDay: LocalDay?

    let items: [Item]
    let kind: ItemCollectionKind

    private var isRefined: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedCategory != nil
            || selectedFilter != .all
            || selectedSort != .defaultOrder
    }

    var body: some View {
        let today = currentDay ?? LocalDay(containing: .now, in: timeZone)
        let selectedDay = LocalDay(containing: selectedDate, in: timeZone)
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
        .stallyListChrome()
        .searchable(
            text: $searchText,
            prompt: Text(kind.searchPrompt)
        )
        .onAppear(perform: refreshCurrentDay)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                refreshCurrentDay()
            }
        }
        .onChange(of: timeZone.identifier) {
            refreshCurrentDay()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.significantTimeChangeNotification
            )
        ) { _ in
            refreshCurrentDay()
        }
    }

    @ViewBuilder
    private func listContent(refinedItems: [Item]) -> some View {
        ItemCollectionRefinementSection(
            kind: kind,
            shownItemCount: refinedItems.count,
            selectedCategory: $selectedCategory,
            selectedFilter: $selectedFilter,
            selectedSort: $selectedSort,
            selectedDate: $selectedDate
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
            }
        } else {
            Section {
                ForEach(refinedItems) { item in
                    NavigationLink(value: StallyNavigationView.DetailRoute.item(item.uuid)) {
                        ItemRow(item: item)
                    }
                }
            }
        }

        if !isSubscribeOn {
            StallyAdvertisementSection(size: .small)
        }
    }

    private func clearRefinements() {
        searchText = ""
        selectedCategory = nil
        selectedFilter = .all
        selectedSort = .defaultOrder
        selectedDate = .now
    }

    private func refreshCurrentDay() {
        currentDay = LocalDay(containing: .now, in: timeZone)
    }
}
