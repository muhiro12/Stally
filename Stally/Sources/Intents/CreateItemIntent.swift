import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct CreateItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Item"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Create Item") {
            \.$name
            \.$note
            \.$link
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var librarySession: StallyLibrarySession
    @Parameter(title: "Name")
    var name: String
    @Parameter(title: "Note")
    var note: String?
    @Parameter(title: "Link")
    var link: String?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ItemEntity> {
        let session = librarySession.writer
        let value = try await IntentAccess.write(container: container, session: session) { context in
            var draft = ItemDraft(name: name, note: note)
            draft.representativeURL = link ?? ""
            return ItemEntity(try ItemOperations.save(draft, context: context))
        }
        return .result(value: value)
    }
}
