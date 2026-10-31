import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct GetPeriodReadingsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Time Together"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Get Time Together") {
            \.$item
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<String> {
        let value = try IntentAccess.read(container: container) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            let readings = try PeriodReadingOperations.readings(
                for: record,
                today: MarkOperations.localDateTime(at: .now, includesTime: false)
            )
            return IntentReadingText.describe(readings)
        }
        return .result(value: value)
    }
}
