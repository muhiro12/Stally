//
//  StallyModelContainerFactory.swift
//  StallyLibrary
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftData

/// Factory helpers for Stally's SwiftData model container.
public enum StallyModelContainerFactory {
    /// Creates the app's persistent model container.
    public static func persistent() throws -> ModelContainer {
        try make(isStoredInMemoryOnly: false)
    }

    /// Creates an in-memory model container for tests and previews.
    public static func inMemory() throws -> ModelContainer {
        try make(isStoredInMemoryOnly: true)
    }

    private static func make(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema([
            Item.self,
            ItemMark.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
