import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct GetItemTagsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Item Tags"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Get Item Tags") {
            \.$item
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<[TagEntity]> {
        let value = try IntentAccess.read(container: container) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            return (record.tags ?? []).map(TagEntity.init)
        }
        return .result(value: value)
    }
}
