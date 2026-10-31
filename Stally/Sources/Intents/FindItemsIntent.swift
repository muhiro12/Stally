import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct FindItemsIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Items"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Find Items") {
            \.$text
            \.$scope
            \.$favoritesOnly
            \.$tag
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Text", default: "")
    var text: String
    @Parameter(title: "Scope", default: .library)
    var scope: ItemArchiveScope
    @Parameter(title: "Favorites Only", default: false)
    var favoritesOnly: Bool
    @Parameter(title: "Tag")
    var tag: TagEntity?

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<[ItemEntity]> {
        let value = try IntentAccess.read(container: container) { context in
            var query = ItemQuery()
            query.text = text
            query.archiveScope = scope.queryScope
            query.favoritesOnly = favoritesOnly
            query.tagID = tag?.id
            return try query.matching(ItemOperations.items(context: context)).map(ItemEntity.init)
        }
        return .result(value: value)
    }
}
