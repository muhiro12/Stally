import AppIntents
import SwiftData

struct CheckStallyTimeTogetherIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Check Time Together", table: "AppIntents")
    static let description = IntentDescription(
        .init("Read an item's start and elapsed time without changing its records.", table: "AppIntents")
    )
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    static var parameterSummary: some ParameterSummary {
        Summary("Check time together for \(\.$item)")
    }

    @Parameter(title: .init("Item", table: "AppIntents"))
    var item: StallyItemEntity

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some ReturnsValue<String> & ProvidesDialog {
        guard let today = LocalDay(containing: .now, in: .current) else {
            throw StallyIntentError.currentDayUnavailable
        }
        let model = try item.model(in: modelContainer.mainContext)
        let report = ItemTimeOperations.report(for: model, today: today)
        return .result(value: report, dialog: .init(.init("\(report)", table: "AppIntents")))
    }
}
