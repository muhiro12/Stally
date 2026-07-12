//
//  StallyMigrationPlan.swift
//  StallyLibrary
//
//  Created by Hiromu Tsuruta on 2026/07/12.
//

import SwiftData

/// Versioned SwiftData schema baseline for Stally persistence.
public enum StallyMigrationPlan: SchemaMigrationPlan {
    static var currentSchema: Schema {
        .init(versionedSchema: StallySchemaV1.self)
    }

    public static var schemas: [any VersionedSchema.Type] {
        [
            StallySchemaV1.self
        ]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

private extension StallyMigrationPlan {
    /// Initial versioned schema for the current rebuild baseline.
    ///
    /// The removed legacy persistence schema is intentionally not a migration source.
    enum StallySchemaV1: VersionedSchema {
        static var models: [any PersistentModel.Type] {
            [
                Item.self,
                ItemMark.self
            ]
        }

        static var versionIdentifier: Schema.Version {
            .init(1, 0, 0)
        }
    }
}
