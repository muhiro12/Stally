//
//  SampleDataOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

import Foundation
import SwiftData

/// Cross-surface use cases for starting an empty Library with sample items.
public enum SampleDataOperations {
    /// Creates localized sample items when the Library contains no items.
    ///
    /// The operation inserts every sample before saving once. If saving fails,
    /// the context rolls back the complete sample set. Calling this operation
    /// for a nonempty Library leaves the existing items unchanged and returns
    /// an empty array.
    ///
    /// - Parameters:
    ///   - context: The model context that owns the Library.
    ///   - locale: The locale used to resolve sample names and notes.
    ///   - createdAt: The creation date of the first sample item.
    /// - Returns: The created items, or an empty array when the Library is not empty.
    @discardableResult
    public static func createItemsIfLibraryIsEmpty(
        in context: ModelContext,
        locale: Locale = .current,
        createdAt: Date = .now
    ) throws -> [Item] {
        try createItemsIfLibraryIsEmpty(
            in: context,
            locale: locale,
            createdAt: createdAt
        ) { context in
            try context.save()
        }
    }

    static func createItemsIfLibraryIsEmpty(
        in context: ModelContext,
        locale: Locale,
        createdAt: Date,
        saving save: (ModelContext) throws -> Void
    ) throws -> [Item] {
        guard try ItemOperations.items(context: context).isEmpty else {
            return []
        }

        let items = try sampleInputs(locale: locale).enumerated().map { index, input in
            try ItemOperations.makeItem(
                input: input,
                createdAt: createdAt.addingTimeInterval(-Double(index))
            )
        }

        for item in items {
            context.insert(item)
        }
        try ItemOperations.saveOrRollback(context, saving: save)

        return items
    }

    private static func sampleInputs(locale: Locale) -> [ItemFormInput] {
        [
            blackWoolCoat(locale: locale),
            whiteEverydaySneakers(locale: locale),
            canvasTote(locale: locale)
        ]
    }

    private static func blackWoolCoat(locale: Locale) -> ItemFormInput {
        .init(
            name: String(
                localized: LocalizedStringResource(
                    "Black Wool Coat",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            ),
            category: .clothing,
            note: String(
                localized: LocalizedStringResource(
                    "The one I reach for on cold mornings.",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            )
        )
    }

    private static func whiteEverydaySneakers(locale: Locale) -> ItemFormInput {
        .init(
            name: String(
                localized: LocalizedStringResource(
                    "White Everyday Sneakers",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            ),
            category: .shoes,
            note: String(
                localized: LocalizedStringResource(
                    "Easy pair for short walks and errands.",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            )
        )
    }

    private static func canvasTote(locale: Locale) -> ItemFormInput {
        .init(
            name: String(
                localized: LocalizedStringResource(
                    "Canvas Tote",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            ),
            category: .bags,
            note: String(
                localized: LocalizedStringResource(
                    "Usually comes with me when I need one extra layer.",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            )
        )
    }
}
