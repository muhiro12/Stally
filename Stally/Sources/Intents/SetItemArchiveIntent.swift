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
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Archived")
    var archived: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            try ItemOperations.setArchived(record, to: archived, context: context)
        }
        return .result()
    }
}
