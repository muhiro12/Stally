import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct GetItemDetailsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Item Details"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Get Item Details") {
            \.$item
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<ItemEntity> {
        let value = try IntentAccess.read(container: container) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            return ItemEntity(record)
        }
        return .result(value: value)
    }
}
