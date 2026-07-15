//
//  StallyPreviewData.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

#if DEBUG
// swiftlint:disable no_magic_numbers
import Foundation
import SwiftData
import SwiftUI
import UIKit

@MainActor
enum StallyPreviewData {
    static let timeZone = TimeZone(secondsFromGMT: 0) ?? .current

    private static let calendar: Calendar = {
        var previewCalendar = Calendar(identifier: .gregorian)
        previewCalendar.timeZone = timeZone
        return previewCalendar
    }()

    static var backupValidationPreview: BackupPreview {
        .init(
            itemCount: 7,
            archivedItemCount: 2,
            markCount: 24,
            existingItemCount: 3,
            newItemCount: 4,
            skippedItemCount: 1,
            marksAddedCount: 11,
            validationIssues: [
                .init(kind: .duplicateItemID, value: "Black Wool Coat"),
                .init(kind: .unknownCategory, value: "Outerwear")
            ]
        )
    }

    static func makeContainer(for scenario: StallyPreviewScenario) -> ModelContainer {
        do {
            let container = try StallyModelContainerFactory.inMemory()
            try seed(scenario: scenario, in: container.mainContext)
            return container
        } catch {
            fatalError("Could not create Stally preview data: \(error)")
        }
    }

    static func items(in container: ModelContainer) -> [Item] {
        do {
            let descriptor = FetchDescriptor<Item>(
                sortBy: [
                    .init(\.createdAt, order: .reverse)
                ]
            )
            return try container.mainContext.fetch(descriptor)
        } catch {
            fatalError("Could not fetch Stally preview items: \(error)")
        }
    }
}

private extension StallyPreviewData {
    static var placeholderPhotoData: Data? {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor(Color.accentColor).setFill()
            context.fill(.init(origin: .zero, size: size))

            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 220, weight: .medium)
            let symbol = UIImage(systemName: "tshirt.fill", withConfiguration: symbolConfiguration)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            let symbolSize = symbol?.size ?? .zero
            symbol?.draw(
                at: .init(
                    x: (size.width - symbolSize.width) / 2,
                    y: (size.height - symbolSize.height) / 2
                )
            )
        }
        return image.pngData()
    }

    static let itemNamesWithPhotos: Set<String> = [
        "Black Wool Coat",
        "Soft Navy Sweater With A Long Familiar Name"
    ]

    static var typicalItemSeeds: [StallyPreviewItemSeed] {
        [
            .init(
                name: "Black Wool Coat",
                category: .clothing,
                note: "The one I reach for on cold mornings.",
                createdDaysAgo: 84,
                markedDaysAgo: [0, 1, 4, 7, 14, 21, 35, 49, 63],
                archivedDaysAgo: nil
            ),
            .init(
                name: "White Everyday Sneakers",
                category: .shoes,
                note: "Easy pair for short walks and errands.",
                createdDaysAgo: 62,
                markedDaysAgo: [0, 2, 3, 5, 8, 13, 21, 34],
                archivedDaysAgo: nil
            ),
            .init(
                name: "Canvas Tote",
                category: .bags,
                note: "Usually comes with me when I need one extra layer.",
                createdDaysAgo: 46,
                markedDaysAgo: [6, 17, 29],
                archivedDaysAgo: nil
            ),
            .init(
                name: "Daily Field Notes",
                category: .notebooks,
                note: "Still waiting for its first stretch of regular use.",
                createdDaysAgo: 24,
                markedDaysAgo: [],
                archivedDaysAgo: nil
            ),
            .init(
                name: "Travel Weekender",
                category: .bags,
                note: "Archived because it only comes out a few times a year.",
                createdDaysAgo: 150,
                markedDaysAgo: [72, 90, 121],
                archivedDaysAgo: 38
            )
        ]
    }

    static var denseItemSeeds: [StallyPreviewItemSeed] {
        [
            .init(
                name: "Soft Navy Sweater With A Long Familiar Name",
                category: .clothing,
                note: """
                Kept for slow mornings and the days that need something familiar.
                The longer note makes dense and Dynamic Type previews easier to inspect.
                """,
                createdDaysAgo: 118,
                markedDaysAgo: [39, 52, 68, 81, 97],
                archivedDaysAgo: nil
            ),
            .init(
                name: "Small Black Notebook",
                category: .notebooks,
                note: "Lives near the desk for small thoughts.",
                createdDaysAgo: 37,
                markedDaysAgo: [12, 18, 25],
                archivedDaysAgo: nil
            ),
            .init(
                name: "Rain Shell",
                category: .clothing,
                note: "Quietly useful when the weather turns.",
                createdDaysAgo: 91,
                markedDaysAgo: [2, 31, 58],
                archivedDaysAgo: nil
            ),
            .init(
                name: "Leather Card Case",
                category: .other,
                note: "",
                createdDaysAgo: 19,
                markedDaysAgo: [1, 9],
                archivedDaysAgo: nil
            ),
            .init(
                name: "Winter Scarf",
                category: .clothing,
                note: "Preserved for colder days.",
                createdDaysAgo: 180,
                markedDaysAgo: [80, 104, 132, 151],
                archivedDaysAgo: 28
            )
        ]
    }

    static func seed(
        scenario: StallyPreviewScenario,
        in context: ModelContext
    ) throws {
        switch scenario {
        case .empty:
            return
        case .typical:
            try seed(typicalItemSeeds, in: context)
        case .dense:
            try seed(typicalItemSeeds + denseItemSeeds, in: context)
        }
    }

    static func seed(
        _ itemSeeds: [StallyPreviewItemSeed],
        in context: ModelContext
    ) throws {
        let now = Date()
        guard let today = LocalDay(containing: now, in: timeZone) else {
            throw CocoaError(.coderInvalidValue)
        }

        for itemSeed in itemSeeds {
            try createItem(
                from: itemSeed,
                in: context,
                now: now,
                today: today
            )
        }
    }

    @discardableResult
    static func createItem(
        from itemSeed: StallyPreviewItemSeed,
        in context: ModelContext,
        now: Date,
        today: LocalDay
    ) throws -> Item {
        let item = try ItemOperations.create(
            context: context,
            input: .init(
                name: itemSeed.name,
                category: itemSeed.category,
                note: itemSeed.note,
                photoData: itemNamesWithPhotos.contains(itemSeed.name)
                    ? placeholderPhotoData
                    : nil
            ),
            createdAt: day(itemSeed.createdDaysAgo, before: now)
        )

        for markedDay in itemSeed.markedDaysAgo {
            guard let localDay = today.adding(days: -markedDay) else {
                throw CocoaError(.coderInvalidValue)
            }

            try ItemOperations.mark(
                item,
                on: localDay,
                today: today,
                context: context
            )
        }

        if let archivedDaysAgo = itemSeed.archivedDaysAgo {
            try ItemOperations.archive(
                item,
                on: day(archivedDaysAgo, before: now),
                context: context
            )
        }

        return item
    }

    static func day(_ daysAgo: Int, before date: Date) -> Date {
        calendar.startOfDay(
            for: calendar.date(
                byAdding: .day,
                value: -daysAgo,
                to: date
            ) ?? date
        )
    }
}
// swiftlint:enable no_magic_numbers
#endif
