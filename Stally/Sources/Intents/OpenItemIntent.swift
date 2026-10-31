import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct OpenItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Item"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Open Item") {
            \.$item
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity

    @MainActor
    func perform() throws -> some IntentResult & OpensIntent {
        let url = try IntentAccess.read(container: container) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            return StallyLinkOperations.url(for: .item(record.uuid))
        }
        return .result(opensIntent: OpenURLIntent(url))
    }
}
