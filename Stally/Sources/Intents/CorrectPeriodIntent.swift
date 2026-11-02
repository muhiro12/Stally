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
            \.$clearStart
            \.$clearEnd
            \.$continuation
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var librarySession: StallyLibrarySession
    @Parameter(title: "Period")
    var period: PeriodEntity
    @Parameter(title: "Start (YYYY, YYYY-MM, or YYYY-MM-DD)")
    var start: String?
    @Parameter(title: "End (YYYY, YYYY-MM, or YYYY-MM-DD)")
    var end: String?
    @Parameter(title: "Clear Start Date", default: false)
    var clearStart: Bool
    @Parameter(title: "Clear End Date", default: false)
    var clearEnd: Bool
    @Parameter(title: "Continuation", default: .unchanged)
    var continuation: PeriodContinuationChange

    @MainActor
    func perform() async throws -> some IntentResult {
        let session = librarySession.writer
        try await IntentAccess.write(container: container, session: session) { context in
            let record = try IntentRecordLookup.record(ItemPeriod.self, uuid: period.id, context: context) { $0.uuid }
            let revisedStart = try IntentTextEdit.value(start, clearing: clearStart, current: record.startLocalDate)
            let revisedEnd = try IntentTextEdit.value(end, clearing: clearEnd, current: record.endLocalDate)
            let isOngoing = continuation.applying(to: record.isOngoing)
            guard revisedStart != record.startLocalDate || revisedEnd != record.endLocalDate
                    || isOngoing != record.isOngoing else {
                return
            }
            try PeriodOperations.correct(
                record,
                input: .init(
                    start: revisedStart,
                    end: revisedEnd,
                    isOngoing: isOngoing
                ),
                today: MarkOperations.localDateTime(at: .now, includesTime: false),
                context: context
            )
        }
        return .result()
    }
}
