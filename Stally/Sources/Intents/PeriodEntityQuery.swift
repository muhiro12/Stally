import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct PeriodEntityQuery: EntityStringQuery {
    private static let suggestionLimit = 20

    @Dependency private var container: ModelContainer

    @MainActor
    func suggestedEntities() throws -> [PeriodEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<ItemPeriod>(sortBy: [.init(\.createdAt, order: .reverse)]))
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.prefix(Self.suggestionLimit).map(PeriodEntity.init)
        }
    }

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [PeriodEntity] {
        try IntentAccess.read(container: container) { context in
            let matches = try context.fetch(FetchDescriptor<ItemPeriod>()).filter { identifiers.contains($0.uuid) }
            guard Set(matches.map(\.uuid)).count == matches.count else { throw RecordError.ambiguousIdentity }
            let indexed = Dictionary(uniqueKeysWithValues: matches.map { ($0.uuid, PeriodEntity($0)) })
            return identifiers.compactMap { indexed[$0] }
        }
    }

    @MainActor
    func entities(matching string: String) throws -> [PeriodEntity] {
        try IntentAccess.read(container: container) { context in
            let records = try context.fetch(FetchDescriptor<ItemPeriod>())
            guard Set(records.map(\.uuid)).count == records.count else { throw RecordError.ambiguousIdentity }
            return records.map(PeriodEntity.init).filter { entity in
                string.isEmpty || entity.name.localizedStandardContains(string)
                    || entity.details.localizedStandardContains(string)
            }
        }
    }
}
