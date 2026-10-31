import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct SetItemRecordingIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Item Recording"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Set Item Recording") {
            \.$item
            \.$enabled
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Enabled")
    var enabled: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            try ItemOperations.setMarkRecordingEnabled(record, to: enabled, context: context)
        }
        return .result()
    }
}
