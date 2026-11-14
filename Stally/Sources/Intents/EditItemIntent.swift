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
            \.$clearNote
            \.$clearLink
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var librarySession: StallyLibrarySession
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Name")
    var name: String?
    @Parameter(title: "Note")
    var note: String?
    @Parameter(title: "Link")
    var link: String?
    @Parameter(title: "Clear Note", default: false)
    var clearNote: Bool
    @Parameter(title: "Clear Link", default: false)
    var clearLink: Bool

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ItemEntity> {
        let session = librarySession.writer
        let value = try await IntentAccess.write(container: container, session: session) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            var draft = ItemOperations.draft(for: record)
            if let name { draft.name = name }
            draft.note = try TextInput.edited(note, clearing: clearNote, current: record.note) ?? ""
            draft.representativeURL = try TextInput.edited(
                link, clearing: clearLink, current: record.representativeURL
            ) ?? ""
            return ItemEntity(try ItemOperations.save(draft, context: context))
        }
        return .result(value: value)
    }
}
