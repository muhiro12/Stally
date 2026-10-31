import Foundation
import SwiftData

/// Callers supply a clean context. Save failure rolls back only this operation's changes.
enum RecordMutation {
    static func validate(_ context: ModelContext, models: [any PersistentModel]) throws {
        guard !context.hasChanges else {
            throw RecordError.pendingChanges
        }
        for model in models {
            guard model.modelContext === context, !model.isDeleted else {
                throw RecordError.wrongContext
            }
        }
    }

    static func save(_ context: ModelContext) throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    static func index<Model: PersistentModel>(_ records: [Model], identity: (Model) -> UUID) throws -> [UUID: Model] {
        var indexed: [UUID: Model] = [:]
        for record in records {
            guard indexed.updateValue(record, forKey: identity(record)) == nil else {
                throw RecordError.ambiguousIdentity
            }
        }
        return indexed
    }

    static func validateName(_ name: String) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RecordError.nameRequired
        }
    }
}
