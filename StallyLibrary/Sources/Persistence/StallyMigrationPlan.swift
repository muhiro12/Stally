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
        .init(versionedSchema: StallySchemaV2.self)
    }

    public static var schemas: [any VersionedSchema.Type] {
        [
            StallySchemaV1.self,
            StallySchemaV2.self
        ]
    }

    public static var stages: [MigrationStage] {
        [.lightweight(fromVersion: StallySchemaV1.self, toVersion: StallySchemaV2.self)]
    }
}

private extension StallyMigrationPlan {
    /// Adds optional start knowledge and a default-enabled Mark policy.
    enum StallySchemaV2: VersionedSchema {
        private static let majorVersion = 2

        static var models: [any PersistentModel.Type] {
            [
                Item.self,
                ItemMark.self
            ]
        }

        static var versionIdentifier: Schema.Version {
            .init(majorVersion, 0, 0)
        }
    }
}
