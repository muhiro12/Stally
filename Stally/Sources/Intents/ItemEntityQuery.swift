import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct ItemEntityQuery: EntityStringQuery {
    private static let suggestionLimit = 20

    @Dependency private var container: ModelContainer

    @MainActor
    func suggestedEntities() throws -> [ItemEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<Item>(sortBy: [.init(\.createdAt, order: .reverse)]))
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.prefix(Self.suggestionLimit).map(ItemEntity.init)
        }
    }

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [ItemEntity] {
        try IntentAccess.read(container: container) { context in
            let matches = try context.fetch(FetchDescriptor<Item>()).filter { identifiers.contains($0.uuid) }
            guard Set(matches.map(\.uuid)).count == matches.count else { throw RecordError.ambiguousIdentity }
            let indexed = Dictionary(uniqueKeysWithValues: matches.map { ($0.uuid, ItemEntity($0)) })
            return identifiers.compactMap { indexed[$0] }
        }
    }

    @MainActor
    func entities(matching string: String) throws -> [ItemEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<Item>())
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.map(ItemEntity.init).filter { entity in
                string.isEmpty || entity.name.localizedStandardContains(string)
                    || entity.details.localizedStandardContains(string)
            }
        }
    }
}
