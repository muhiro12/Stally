import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct AddPeriodIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Period"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Add Period") {
            \.$item
            \.$start
            \.$end
            \.$ongoing
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Start (YYYY, YYYY-MM, or YYYY-MM-DD)")
    var start: String?
    @Parameter(title: "End (Unknown If Empty)")
    var end: String?
    @Parameter(title: "Ongoing", default: true)
    var ongoing: Bool

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<PeriodEntity> {
        let value = try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            return PeriodEntity(
                try PeriodOperations.add(
                    to: record,
                    input: .init(
                        start: IntentDateInput.optional(start),
                        end: IntentDateInput.optional(end),
                        isOngoing: ongoing
                    ),
                    today: MarkOperations.localDateTime(at: .now, includesTime: false),
                    context: context
                )
            )
        }
        return .result(value: value)
    }
}
