import Foundation
import StallyLibrary
import SwiftData

@MainActor
enum IntentRecordLookup {
    static func record<Model: PersistentModel>(
        _: Model.Type,
        uuid: UUID,
        context: ModelContext,
        identity: (Model) -> UUID
    ) throws -> Model {
        let matches = try context.fetch(FetchDescriptor<Model>()).filter { identity($0) == uuid }
        guard matches.count <= 1 else { throw RecordError.ambiguousIdentity }
        guard let record = matches.first else { throw RecordError.missingRecord }
        return record
    }
}
