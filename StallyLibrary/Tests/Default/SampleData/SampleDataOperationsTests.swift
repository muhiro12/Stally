//
//  SampleDataOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/13.
//

import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

private enum ExpectedSampleDataSaveError: Error {
    case rejected
}

extension SwiftDataOperationsTests {
    @Suite
    struct SampleDataOperationsTests {
        private var testDate: Date {
            Date(timeIntervalSince1970: 1_750_000_000)
        }

        @Test
        func `sample items resolve English and Japanese values`() throws {
            let englishContext = try makeContext()
            let japaneseContext = try makeContext()

            let englishItems = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: englishContext,
                locale: .init(identifier: "en"),
                createdAt: testDate
            )
            let japaneseItems = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: japaneseContext,
                locale: .init(identifier: "ja"),
                createdAt: testDate
            )

            #expect(englishItems.map(\.name) == [
                "Black Wool Coat",
                "White Everyday Sneakers",
                "Canvas Tote"
            ])
            #expect(englishItems.map(\.note) == [
                "The one I reach for on cold mornings.",
                "Easy pair for short walks and errands.",
                "Usually comes with me when I need one extra layer."
            ])
            #expect(japaneseItems.map(\.name) == [
                "黒のウールコート",
                "白の普段履きスニーカー",
                "キャンバストート"
            ])
            #expect(japaneseItems.map(\.note) == [
                "寒い朝につい手が伸びる一着。",
                "近所の散歩や買い物に気軽に履ける一足。",
                "羽織りものを一枚持ちたい日に、たいてい一緒に連れていく。"
            ])
        }

        @Test
        func `sample items are created together in the expected order`() throws {
            let context = try makeContext()

            let createdItems = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: context,
                locale: .init(identifier: "en"),
                createdAt: testDate
            )
            let fetchedItems = try ItemOperations.items(context: context)

            #expect(createdItems.count == 3)
            #expect(fetchedItems.map(\.uuid) == createdItems.map(\.uuid))
            #expect(fetchedItems.map(\.category) == [.clothing, .shoes, .bags])
            #expect(fetchedItems.map(\.createdAt) == [
                testDate,
                testDate.addingTimeInterval(-1),
                testDate.addingTimeInterval(-2)
            ])
            #expect(fetchedItems.allSatisfy { item in
                !item.isArchived && item.marks.isEmpty && item.photoData == nil
            })
        }

        @Test
        func `repeated creation does not duplicate sample items`() throws {
            let context = try makeContext()

            let firstItems = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: context,
                locale: .init(identifier: "en"),
                createdAt: testDate
            )
            let repeatedItems = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: context,
                locale: .init(identifier: "en"),
                createdAt: testDate
            )

            #expect(firstItems.count == 3)
            #expect(repeatedItems.isEmpty)
            #expect(try ItemOperations.items(context: context).count == 3)
        }

        @Test
        func `existing user item prevents sample creation`() throws {
            let context = try makeContext()
            let existingItem = try ItemOperations.create(
                context: context,
                input: .init(name: "My Tote", category: .bags),
                createdAt: testDate
            )

            let createdItems = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: context,
                locale: .init(identifier: "en"),
                createdAt: testDate
            )

            #expect(createdItems.isEmpty)
            #expect(try ItemOperations.items(context: context).map(\.uuid) == [existingItem.uuid])
        }

        @Test
        func `failed save rolls back every sample and allows retry`() throws {
            let context = try makeContext()

            #expect(throws: ExpectedSampleDataSaveError.self) {
                try SampleDataOperations.createItemsIfLibraryIsEmpty(
                    in: context,
                    locale: .init(identifier: "en"),
                    createdAt: testDate
                ) { pendingContext in
                    #expect(try ItemOperations.items(context: pendingContext).count == 3)
                    throw ExpectedSampleDataSaveError.rejected
                }
            }

            let retryContext = ModelContext(context.container)
            #expect(try ItemOperations.items(context: retryContext).isEmpty)

            let retriedItems = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: retryContext,
                locale: .init(identifier: "en"),
                createdAt: testDate
            )
            #expect(retriedItems.count == 3)
            #expect(try ItemOperations.items(context: retryContext).count == 3)
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }
    }
}
