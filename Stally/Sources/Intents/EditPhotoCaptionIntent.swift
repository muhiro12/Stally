import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct EditPhotoCaptionIntent: AppIntent {
    static let title: LocalizedStringResource = "Edit Photo Caption"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Edit Photo Caption") {
            \.$photo
            \.$caption
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Photo")
    var photo: PhotoEntity
    @Parameter(title: "Caption", default: "")
    var caption: String

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(ItemPhoto.self, uuid: photo.id, context: context) { $0.uuid }
            guard let owner = record.item else { throw RecordError.missingRecord }
            var draft = ItemOperations.draft(for: owner)
            guard let index = draft.photos.firstIndex(where: { $0.id == photo.id }) else {
                throw RecordError.missingRecord
            }
            draft.photos[index].caption = caption
            _ = try ItemOperations.save(draft, context: context)
        }
        return .result()
    }
}
