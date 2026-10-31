import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct MovePhotoIntent: AppIntent {
    static let title: LocalizedStringResource = "Move Photo"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Move Photo") {
            \.$photo
            \.$position
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Photo")
    var photo: PhotoEntity
    @Parameter(title: "Position (Starting at 1)")
    var position: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(ItemPhoto.self, uuid: photo.id, context: context) { $0.uuid }
            guard let owner = record.item else { throw RecordError.missingRecord }
            var draft = ItemOperations.draft(for: owner)
            guard let index = draft.photos.firstIndex(where: { $0.id == photo.id }) else {
                throw RecordError.missingRecord
            }
            guard (1...draft.photos.count).contains(position) else { throw RecordError.invalidPhoto }
            let moved = draft.photos.remove(at: index)
            draft.photos.insert(moved, at: position - 1)
            _ = try ItemOperations.save(draft, context: context)
        }
        return .result()
    }
}
