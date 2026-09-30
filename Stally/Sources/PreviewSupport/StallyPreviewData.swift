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
    static let timeZone = StallyFixtureOperations.timeZone
    static let referenceDate = StallyFixtureOperations.referenceDate

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
            try StallyFixtureOperations.seed(
                scenario,
                in: container.mainContext,
                locale: .current,
                photoData: placeholderPhotoData
            )
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
            UIColor.accent.setFill()
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
}
// swiftlint:enable no_magic_numbers
#endif
