import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct SetItemArchiveIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Item Archive"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Set Item Archive") {
            \.$item
            \.$archived
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var librarySession: StallyLibrarySession
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Archived")
    var archived: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        let session = librarySession.writer
        try await IntentAccess.write(container: container, session: session) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            try ItemOperations.setArchived(record, to: archived, context: context)
        }
        return .result()
    }
}
