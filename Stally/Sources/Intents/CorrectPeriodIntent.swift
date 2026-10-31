import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct CorrectPeriodIntent: AppIntent {
    static let title: LocalizedStringResource = "Correct Period"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Correct Period") {
            \.$period
            \.$start
            \.$end
            \.$ongoing
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Period")
    var period: PeriodEntity
    @Parameter(title: "Start (YYYY, YYYY-MM, or YYYY-MM-DD)")
    var start: String?
    @Parameter(title: "End (Unknown If Empty)")
    var end: String?
    @Parameter(title: "Ongoing", default: true)
    var ongoing: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(ItemPeriod.self, uuid: period.id, context: context) { $0.uuid }
            try PeriodOperations.correct(
                record,
                input: .init(
                    start: IntentDateInput.optional(start),
                    end: IntentDateInput.optional(end),
                    isOngoing: ongoing
                ),
                today: MarkOperations.localDateTime(at: .now, includesTime: false),
                context: context
            )
        }
        return .result()
    }
}
