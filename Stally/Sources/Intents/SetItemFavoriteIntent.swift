import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct SetItemFavoriteIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Item Favorite"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Set Item Favorite") {
            \.$item
            \.$favorite
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var librarySession: StallyLibrarySession
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Favorite")
    var favorite: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        let session = librarySession.writer
        try await IntentAccess.write(container: container, session: session) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            try ItemOperations.setFavorite(record, to: favorite, context: context)
        }
        return .result()
    }
}
