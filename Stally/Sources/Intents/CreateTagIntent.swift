import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct CreateTagIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Tag"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Create Tag") {
            \.$name
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Name")
    var name: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<TagEntity> {
        let value = try await IntentAccess.write(container: container, updates: updates) { context in
            TagEntity(try TagOperations.create(name: name, context: context))
        }
        return .result(value: value)
    }
}
