import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct DeleteItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Item"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Delete Item") {
            \.$item
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        try await requestConfirmation(dialog: "Delete this Item and its Marks, periods, and photos?")
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            try ItemOperations.delete(record, context: context)
        }
        return .result()
    }
}
