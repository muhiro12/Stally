//
//  ItemCollectionOptions.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

/// Search, category, filter, and sort choices for an item collection.
public struct ItemCollectionOptions: Sendable {
    public var searchText: String
    public var category: ItemCategory?
    public var filter: ItemCollectionFilter
    public var sort: ItemCollectionSort

    public init(
        searchText: String = "",
        category: ItemCategory? = nil,
        filter: ItemCollectionFilter = .all,
        sort: ItemCollectionSort = .defaultOrder
    ) {
        self.searchText = searchText
        self.category = category
        self.filter = filter
        self.sort = sort
    }
}
