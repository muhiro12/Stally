//
//  ItemPhotoItemOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import Foundation
import StallyLibrary
import SwiftData
import Testing

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
    }
}
