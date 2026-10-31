import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct AddMarkIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Mark on Date"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Add Mark on Date") {
            \.$item
            \.$localDateTime
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Date (YYYY-MM-DD or YYYY-MM-DDTHH:mm)")
    var localDateTime: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<MarkEntity> {
        let value = try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            return MarkEntity(try MarkOperations.add(to: record, localDateTime: localDateTime, context: context))
        }
        return .result(value: value)
    }
}
