import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct ResumePeriodIntent: AppIntent {
    static let title: LocalizedStringResource = "Resume with New Period"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Resume with New Period") {
            \.$period
            \.$start
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Period")
    var period: PeriodEntity
    @Parameter(title: "Start (Unknown If Empty)")
    var start: String?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<PeriodEntity> {
        let value = try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try IntentRecordLookup.record(ItemPeriod.self, uuid: period.id, context: context) { $0.uuid }
            return PeriodEntity(
                try PeriodOperations.resume(
                    record,
                    on: IntentDateInput.optional(start),
                    today: MarkOperations.localDateTime(at: .now, includesTime: false),
                    context: context
                )
            )
        }
        return .result(value: value)
    }
}
