import Foundation
import SwiftData

public extension TagOperations {
    /// Reviews bounded reassignment; equal names alone never select or combine Tags.
    static func reviewConsolidation(source: Tag, survivor: Tag, context: ModelContext) throws -> TagConsolidation {
        try RecordMutation.validate(context, models: [source, survivor])
        guard source.uuid != survivor.uuid,
              Set((source.items ?? []).map(\.uuid)).count == (source.items ?? []).count,
              Set((survivor.items ?? []).map(\.uuid)).count == (survivor.items ?? []).count else {
            throw RecordError.ambiguousIdentity
        }
        return .init(
            sourceID: source.uuid,
            survivorID: survivor.uuid,
            sourceName: source.name,
            survivorName: survivor.name,
            affectedItemIDs: Set((source.items ?? []).map(\.uuid)),
            survivorItemIDs: Set((survivor.items ?? []).map(\.uuid))
        )
    }

    /// Rechecks the reviewed membership, reassigns affected Items, and deletes only the source Tag.
    static func consolidate(_ review: TagConsolidation, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [])
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let tags = try writer.fetch(FetchDescriptor<Tag>())
        let sources = tags.filter { $0.uuid == review.sourceID }
        let survivors = tags.filter { $0.uuid == review.survivorID }
        guard sources.count == 1, survivors.count == 1, let source = sources.first, let survivor = survivors.first
        else {
            throw RecordError.ambiguousIdentity
        }
        guard source.name == review.sourceName, survivor.name == review.survivorName,
              Set((source.items ?? []).map(\.uuid)) == review.affectedItemIDs,
              Set((survivor.items ?? []).map(\.uuid)) == review.survivorItemIDs
        else { throw RecordError.staleReview }
        do {
            for item in source.items ?? [] {
                var assigned = (item.tags ?? []).filter { $0.uuid != source.uuid }
                if !assigned.contains(where: { $0.uuid == survivor.uuid }) { assigned.append(survivor) }
                item.tags = assigned
            }
            writer.delete(source)
            try writer.save()
        } catch {
            writer.rollback()
            throw error
        }
    }
}
