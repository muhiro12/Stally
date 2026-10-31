import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct TagEntityQuery: EntityStringQuery {
    private static let suggestionLimit = 20

    @Dependency private var container: ModelContainer

    @MainActor
    func suggestedEntities() throws -> [TagEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(
                FetchDescriptor<StallyLibrary.Tag>(sortBy: [.init(\.name, order: .forward)])
            )
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.prefix(Self.suggestionLimit).map(TagEntity.init)
        }
    }

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [TagEntity] {
        try IntentAccess.read(container: container) { context in
            let matches = try context.fetch(FetchDescriptor<StallyLibrary.Tag>()).filter { record in
                identifiers.contains(record.uuid)
            }
            guard Set(matches.map(\.uuid)).count == matches.count else { throw RecordError.ambiguousIdentity }
            let indexed = Dictionary(uniqueKeysWithValues: matches.map { ($0.uuid, TagEntity($0)) })
            return identifiers.compactMap { indexed[$0] }
        }
    }

    @MainActor
    func entities(matching string: String) throws -> [TagEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<StallyLibrary.Tag>())
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.map(TagEntity.init).filter { entity in
                string.isEmpty || entity.name.localizedStandardContains(string)
                    || entity.details.localizedStandardContains(string)
            }
        }
    }
}
