//
//  ItemPhotoItemOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import Foundation
import ImageIO
import StallyLibrary
import SwiftData
import Testing
import UniformTypeIdentifiers

extension SwiftDataOperationsTests {
    @Suite
    struct ItemPhotoItemOperationsTests {
        @Test
        func `create rejects unreadable photo data without inserting an item`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())

            #expect(throws: ItemValidationError.photoUnreadable) {
                try ItemOperations.create(
                    context: context,
                    input: .init(
                        name: "Canvas Tote",
                        category: .bags,
                        photoData: Data([0x01, 0x02, 0x03])
                    )
                )
            }

            #expect(try context.fetch(FetchDescriptor<Item>()).isEmpty)
        }

        @Test
        func `create normalizes a metadata-bearing JPEG before storage`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let sourceData = try TestPhotoFixtures.jpegData(
                width: 80,
                height: 120,
                orientation: .right,
                includesSourceMetadata: true
            )

            let item = try ItemOperations.create(
                context: context,
                input: .init(
                    name: "Canvas Tote",
                    category: .bags,
                    photoData: sourceData
                )
            )
            let storedData = try #require(item.photoData)
            let properties = try TestPhotoInspection.properties(in: storedData)

            #expect(storedData != sourceData)
            #expect(properties.typeIdentifier == UTType.jpeg.identifier)
            #expect(properties.orientation == nil)
            #expect(!properties.containsAlpha)
            #expect(!properties.containsSourceMetadata)
            try ItemPhotoOperations.validate(storedData)
        }

        @Test
        func `create normalizes an alpha PNG before storage`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let sourceData = try TestPhotoFixtures.pngData(
                width: 80,
                height: 120,
                alpha: 0.5
            )

            let item = try ItemOperations.create(
                context: context,
                input: .init(
                    name: "Canvas Tote",
                    category: .bags,
                    photoData: sourceData
                )
            )
            let storedData = try #require(item.photoData)
            let properties = try TestPhotoInspection.properties(in: storedData)

            #expect(properties.typeIdentifier == UTType.jpeg.identifier)
            #expect(!properties.containsAlpha)
            try ItemPhotoOperations.validate(storedData)
        }

        @Test
        func `update preserves canonical photo bytes`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let preparedData = try TestPhotoFixtures.preparedData()
            let item = try ItemOperations.create(
                context: context,
                input: .init(
                    name: "Canvas Tote",
                    category: .bags,
                    photoData: preparedData
                )
            )

            try ItemOperations.update(
                item,
                input: .init(
                    name: "Daily Canvas Tote",
                    category: .bags,
                    photoData: item.photoData
                ),
                context: context
            )

            #expect(item.photoData == preparedData)
        }
    }
}
