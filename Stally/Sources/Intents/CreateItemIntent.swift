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
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Name")
    var name: String
    @Parameter(title: "Note", default: "")
    var note: String
    @Parameter(title: "Link", default: "")
    var link: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ItemEntity> {
        let value = try await IntentAccess.write(container: container, updates: updates) { context in
            var draft = ItemDraft()
            draft.name = name
            draft.note = note
            draft.representativeURL = link
            return ItemEntity(try ItemOperations.save(draft, context: context))
        }
        return .result(value: value)
    }
}
