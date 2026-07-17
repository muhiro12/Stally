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

        private var testTimeZone: TimeZone {
            TimeZone(secondsFromGMT: 0) ?? .current
        }

        @Test
        func `sample items resolve English and Japanese values`() throws {
            let englishContext = try makeContext()
            let japaneseContext = try makeContext()

            let englishItems = try makeSampleItems(
                in: englishContext,
                locale: .init(identifier: "en")
            )
            let japaneseItems = try makeSampleItems(
                in: japaneseContext,
                locale: .init(identifier: "ja")
            )

            #expect(englishItems.map(\.name) == [
                "Black Wool Coat",
                "White Everyday Sneakers",
                "Canvas Tote",
                "Daily Field Notes",
                "Travel Weekender"
            ])
            #expect(englishItems.map(\.note) == [
                "The one I reach for on cold mornings.",
                "Easy pair for short walks and errands.",
                "Usually comes with me when I need one extra layer.",
                "Still waiting for its first stretch of regular use.",
                "Archived because it only comes out a few times a year."
            ])
            #expect(japaneseItems.map(\.name) == [
                "黒のウールコート",
                "白の普段履きスニーカー",
                "キャンバストート",
                "日々のフィールドノート",
                "旅行用ボストンバッグ"
            ])
            #expect(japaneseItems.map(\.note) == [
                "寒い朝につい手が伸びる一着。",
                "近所の散歩や買い物に気軽に履ける一足。",
                "羽織りものを一枚持ちたい日に、たいてい一緒に連れていく。",
                "まだ、日常的に使うきっかけを待っている。",
                "年に数回しか出番がないので、アーカイブしてある。"
            ])
            #expect(englishItems.map(\.uuid) == japaneseItems.map(\.uuid))
        }

        @Test
        func `sample items include representative history and archive states`() throws {
            let context = try makeContext()
            let items = try makeSampleItems(in: context)
            let today = try #require(
                LocalDay(containing: testDate, in: testTimeZone)
            )

            #expect(items.count == 5)
            #expect(Set(items.map(\.uuid)).count == items.count)
            #expect(items.map(\.category) == [
                .clothing,
                .shoes,
                .bags,
                .notebooks,
                .bags
            ])
            #expect(items.map(\.marks.count) == [9, 8, 3, 0, 3])
            #expect(items.map(\.isArchived) == [false, false, false, false, true])
            #expect(items.compactMap { item in
                LocalDay(containing: item.createdAt, in: testTimeZone)
            } == [
                today.adding(days: -84),
                today.adding(days: -62),
                today.adding(days: -46),
                today.adding(days: -24),
                today.adding(days: -150)
            ])
            #expect(
                SampleDataOperations.summary(for: items)
                    == .init(itemCount: 5, markCount: 23)
            )
        }

        @Test
        func `repeated creation does not duplicate sample items`() throws {
            let context = try makeContext()

            let firstItems = try makeSampleItems(in: context)
            let repeatedItems = try makeSampleItems(in: context)

            #expect(firstItems.count == 5)
            #expect(repeatedItems.isEmpty)
            #expect(try ItemOperations.items(context: context).count == 5)
        }

        @Test
        func `existing user item prevents sample creation`() throws {
            let context = try makeContext()
            let existingItem = try ItemOperations.create(
                context: context,
                input: .init(name: "My Tote", category: .bags),
                createdAt: testDate
            )

            let createdItems = try makeSampleItems(in: context)

            #expect(createdItems.isEmpty)
            #expect(try ItemOperations.items(context: context).map(\.uuid) == [existingItem.uuid])
        }

        @Test
        func `removing samples preserves independently created items`() throws {
            let context = try makeContext()
            let sampleItems = try makeSampleItems(in: context)
            let userItem = try ItemOperations.create(
                context: context,
                input: .init(name: "My Umbrella", category: .other),
                createdAt: testDate
            )
            let editedSample = sampleItems[2]
            try ItemOperations.update(
                editedSample,
                input: .init(name: "My Edited Sample", category: .bags),
                context: context
            )
            let today = try #require(
                LocalDay(containing: testDate, in: testTimeZone)
            )
            let addedDay = try #require(today.adding(days: -2))
            try ItemOperations.mark(
                editedSample,
                on: addedDay,
                today: today,
                context: context
            )

            let result = try SampleDataOperations.removeSampleItems(in: context)
            let remainingItems = try ItemOperations.items(context: context)

            #expect(result == .init(itemCount: 5, markCount: 24))
            #expect(remainingItems.map(\.uuid) == [userItem.uuid])
            #expect(SampleDataOperations.summary(for: remainingItems).isEmpty)
        }

        @Test
        func `sample identity survives backup replacement`() throws {
            let sourceContext = try makeContext()
            let sourceItems = try makeSampleItems(in: sourceContext)
            let snapshot = BackupOperations.snapshot(
                for: sourceItems,
                exportedAt: testDate
            )
            let destinationContext = try makeContext()

            try BackupOperations.replaceLibrary(
                snapshot: snapshot,
                context: destinationContext
            )
            let restoredItems = try ItemOperations.items(context: destinationContext)

            #expect(
                SampleDataOperations.summary(for: restoredItems)
                    == .init(itemCount: 5, markCount: 23)
            )
        }

        @Test
        func `failed creation rolls back every sample and allows retry`() throws {
            let context = try makeContext()

            #expect(throws: ExpectedSampleDataSaveError.self) {
                try SampleDataOperations.createItemsIfLibraryIsEmpty(
                    in: context,
                    locale: .init(identifier: "en"),
                    timeZone: testTimeZone,
                    createdAt: testDate
                ) { pendingContext in
                    let pendingItems = try ItemOperations.items(context: pendingContext)
                    #expect(
                        SampleDataOperations.summary(for: pendingItems)
                            == .init(itemCount: 5, markCount: 23)
                    )
                    throw ExpectedSampleDataSaveError.rejected
                }
            }

            let retryContext = ModelContext(context.container)
            #expect(try ItemOperations.items(context: retryContext).isEmpty)

            let retriedItems = try makeSampleItems(in: retryContext)
            #expect(retriedItems.count == 5)
            #expect(try ItemOperations.items(context: retryContext).count == 5)
        }

        @Test
        func `failed removal restores every sample record`() throws {
            let context = try makeContext()
            try makeSampleItems(in: context)

            #expect(throws: ExpectedSampleDataSaveError.self) {
                try SampleDataOperations.removeSampleItems(in: context) { pendingContext in
                    #expect(try ItemOperations.items(context: pendingContext).isEmpty)
                    throw ExpectedSampleDataSaveError.rejected
                }
            }

            let restoredContext = ModelContext(context.container)
            let restoredItems = try ItemOperations.items(context: restoredContext)
            #expect(
                SampleDataOperations.summary(for: restoredItems)
                    == .init(itemCount: 5, markCount: 23)
            )
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func makeSampleItems(
            in context: ModelContext,
            locale: Locale = .init(identifier: "en")
        ) throws -> [Item] {
            try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: context,
                locale: locale,
                timeZone: testTimeZone,
                createdAt: testDate
            )
        }
    }
}
