import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct PhotoEntityQuery: EntityStringQuery {
    private static let suggestionLimit = 20

    @Dependency private var container: ModelContainer

    @MainActor
    func suggestedEntities() throws -> [PhotoEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<ItemPhoto>(sortBy: [.init(\.createdAt, order: .reverse)]))
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.prefix(Self.suggestionLimit).map(PhotoEntity.init)
        }
    }

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [PhotoEntity] {
        try IntentAccess.read(container: container) { context in
            let matches = try context.fetch(FetchDescriptor<ItemPhoto>()).filter { identifiers.contains($0.uuid) }
            guard Set(matches.map(\.uuid)).count == matches.count else { throw RecordError.ambiguousIdentity }
            let indexed = Dictionary(uniqueKeysWithValues: matches.map { ($0.uuid, PhotoEntity($0)) })
            return identifiers.compactMap { indexed[$0] }
        }
    }

    @MainActor
    func entities(matching string: String) throws -> [PhotoEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<ItemPhoto>())
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.map(PhotoEntity.init).filter { entity in
                string.isEmpty || entity.name.localizedStandardContains(string)
                    || entity.details.localizedStandardContains(string)
            }
        }
    }
}
