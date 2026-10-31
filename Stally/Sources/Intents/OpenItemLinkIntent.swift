import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct OpenItemLinkIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Item Link"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Open Item Link") {
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
            guard let text = record.representativeURL, let url = URL(string: text) else { throw RecordError.invalidURL }
            return url
        }
        return .result(opensIntent: OpenURLIntent(url))
    }
}
