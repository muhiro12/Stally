import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct MarkEntityQuery: EntityStringQuery {
    private static let suggestionLimit = 20

    @Dependency private var container: ModelContainer

    @MainActor
    func suggestedEntities() throws -> [MarkEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<ItemMark>(sortBy: [.init(\.createdAt, order: .reverse)]))
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.prefix(Self.suggestionLimit).map(MarkEntity.init)
        }
    }

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [MarkEntity] {
        try IntentAccess.read(container: container) { context in
            let matches = try context.fetch(FetchDescriptor<ItemMark>()).filter { identifiers.contains($0.uuid) }
            guard Set(matches.map(\.uuid)).count == matches.count else { throw RecordError.ambiguousIdentity }
            let indexed = Dictionary(uniqueKeysWithValues: matches.map { ($0.uuid, MarkEntity($0)) })
            return identifiers.compactMap { indexed[$0] }
        }
    }

    @MainActor
    func entities(matching string: String) throws -> [MarkEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<ItemMark>())
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.map(MarkEntity.init).filter { entity in
                string.isEmpty || entity.name.localizedStandardContains(string)
                    || entity.details.localizedStandardContains(string)
            }
        }
    }
}
