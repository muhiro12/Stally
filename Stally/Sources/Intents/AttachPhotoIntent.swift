import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct AttachPhotoIntent: AppIntent {
    static let title: LocalizedStringResource = "Attach Photo"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Attach Photo") {
            \.$item
            \.$file
            \.$caption
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Image")
    var file: IntentFile
    @Parameter(title: "Caption", default: "")
    var caption: String

    @MainActor
    func perform() async throws -> some IntentResult {
        let prepared = try await IntentPhotoInput.prepare(file)
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            var draft = ItemOperations.draft(for: record)
            draft.photos.append(.init(prepared: prepared, caption: caption))
            _ = try ItemOperations.save(draft, context: context)
        }
        return .result()
    }
}
