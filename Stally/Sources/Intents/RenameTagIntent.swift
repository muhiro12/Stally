import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct RenameTagIntent: AppIntent {
    static let title: LocalizedStringResource = "Rename Tag"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Rename Tag") {
            \.$tag
            \.$name
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Tag")
    var tag: TagEntity
    @Parameter(title: "Name")
    var name: String

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(
                StallyLibrary.Tag.self,
                uuid: tag.id,
                context: context,
                identity: \.uuid
            )
            try TagOperations.rename(record, name: name, context: context)
        }
        return .result()
    }
}
