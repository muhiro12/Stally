import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct GetItemPeriodsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Item Periods"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Get Item Periods") {
            \.$item
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<[PeriodEntity]> {
        let value = try IntentAccess.read(container: container) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            return (record.periods ?? []).map(PeriodEntity.init)
        }
        return .result(value: value)
    }
}
