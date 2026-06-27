//
//  StallyModelContainerFactory.swift
//  StallyLibrary
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftData

/// Factory helpers for Stally's SwiftData model container.
public enum StallyModelContainerFactory {
    /// CloudKit container identifier used by the app target entitlement.
    public static let cloudKitContainerIdentifier = "iCloud.com.muhiro12.Stally"

    /// SwiftData schema shared by persistent, preview, and test containers.
    public static var schema: Schema {
        Schema([
            Item.self,
            ItemMark.self
        ])
    }

    /// Creates the app's CloudKit-backed persistent model container.
    public static func persistent() throws -> ModelContainer {
        try persistent(syncsWithCloudKit: true)
    }

    /// Creates a persistent model container for runtime use.
    public static func persistent(syncsWithCloudKit: Bool) throws -> ModelContainer {
        try make(
            isStoredInMemoryOnly: false,
            cloudKitDatabase: syncsWithCloudKit ? .automatic : .none
        )
    }

    /// Creates an in-memory model container for tests and previews.
    public static func inMemory() throws -> ModelContainer {
        try make(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
    }

    private static func make(
        isStoredInMemoryOnly: Bool,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        let modelSchema = Self.schema
        let configuration = ModelConfiguration(
            schema: modelSchema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: cloudKitDatabase
        )

        return try ModelContainer(for: modelSchema, configurations: [configuration])
    }
}
