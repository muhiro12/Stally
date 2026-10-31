import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct EditItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Edit Item Details"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Edit Item Details") {
            \.$item
            \.$name
            \.$note
            \.$link
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Name")
    var name: String?
    @Parameter(title: "Note")
    var note: String?
    @Parameter(title: "Link")
    var link: String?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ItemEntity> {
        let value = try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            var draft = ItemOperations.draft(for: record)
            if let name { draft.name = name }
            if let note { draft.note = note }
            if let link { draft.representativeURL = link }
            return ItemEntity(try ItemOperations.save(draft, context: context))
        }
        return .result(value: value)
    }
}
