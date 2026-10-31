import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct DeletePeriodIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Period"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Delete Period") {
            \.$period
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Period")
    var period: PeriodEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        try await requestConfirmation(dialog: "Delete this period?")
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(ItemPeriod.self, uuid: period.id, context: context) { $0.uuid }
            try PeriodOperations.delete(record, context: context)
        }
        return .result()
    }
}
