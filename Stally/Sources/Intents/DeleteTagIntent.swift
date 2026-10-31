import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct DeleteTagIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Tag"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Delete Tag") {
            \.$tag
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Tag")
    var tag: TagEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        try await requestConfirmation(dialog: "Delete this Tag and remove it from all Items?")
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(
                StallyLibrary.Tag.self,
                uuid: tag.id,
                context: context,
                identity: \.uuid
            )
            try TagOperations.delete(record, context: context)
        }
        return .result()
    }
}
