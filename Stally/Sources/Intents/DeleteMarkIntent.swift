import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct DeleteMarkIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Mark"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Delete Mark") {
            \.$mark
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Mark")
    var mark: MarkEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        try await requestConfirmation(dialog: "Delete this Mark?")
        try await IntentAccess.write(container: container, updates: updates) { context in
            try MarkOperations.undoAddition(uuid: mark.id, context: context)
        }
        return .result()
    }
}
