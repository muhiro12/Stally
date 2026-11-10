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
            \.$clearCaption
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var librarySession: StallyLibrarySession
    @Parameter(title: "Photo")
    var photo: PhotoEntity
    @Parameter(title: "Caption")
    var caption: String?
    @Parameter(title: "Clear Caption", default: false)
    var clearCaption: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        let session = librarySession.writer
        try await IntentAccess.write(container: container, session: session) { context in
            let record = try IntentRecordLookup.record(ItemPhoto.self, uuid: photo.id, context: context) { $0.uuid }
            guard let owner = record.item else { throw RecordError.missingRecord }
            let value = try TextInput.edited(caption, clearing: clearCaption, current: record.caption)
            guard record.caption != value else {
                return
            }
            var draft = ItemOperations.draft(for: owner)
            guard let index = draft.photos.firstIndex(where: { $0.id == photo.id }) else {
                throw RecordError.missingRecord
            }
            draft.photos[index].caption = value ?? ""
            _ = try ItemOperations.save(draft, context: context)
        }
        return .result()
    }
}
