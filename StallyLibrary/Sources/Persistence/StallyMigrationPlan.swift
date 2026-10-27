import SwiftData

/// A new baseline, deliberately excluding automatic reinterpretation of development stores.
public enum StallyMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [StallySchemaV3.self] }
    public static var stages: [MigrationStage] { [] }
}
