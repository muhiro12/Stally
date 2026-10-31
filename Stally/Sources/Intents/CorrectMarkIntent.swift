import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct CorrectMarkIntent: AppIntent {
    static let title: LocalizedStringResource = "Correct Mark"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Correct Mark") {
            \.$mark
            \.$localDateTime
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Mark")
    var mark: MarkEntity
    @Parameter(title: "Correct Date")
    var localDateTime: String

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(ItemMark.self, uuid: mark.id, context: context) { $0.uuid }
            try MarkOperations.correct(record, localDateTime: localDateTime, context: context)
        }
        return .result()
    }
}
