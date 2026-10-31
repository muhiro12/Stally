import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct EndPeriodIntent: AppIntent {
    static let title: LocalizedStringResource = "End Period"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("End Period") {
            \.$period
            \.$end
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Period")
    var period: PeriodEntity
    @Parameter(title: "End (Unknown If Empty)")
    var end: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(ItemPeriod.self, uuid: period.id, context: context) { $0.uuid }
            try PeriodOperations.end(
                record,
                on: IntentDateInput.optional(end),
                today: MarkOperations.localDateTime(at: .now, includesTime: false),
                context: context
            )
        }
        return .result()
    }
}
