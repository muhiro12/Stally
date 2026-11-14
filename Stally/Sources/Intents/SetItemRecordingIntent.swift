import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct SetItemRecordingIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Item Recording"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Set Item Recording") {
            \.$item
            \.$enabled
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var librarySession: StallyLibrarySession
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Enabled")
    var enabled: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        let session = librarySession.writer
        try await IntentAccess.write(container: container, session: session) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            try ItemOperations.setMarkRecordingEnabled(record, to: enabled, context: context)
        }
        return .result()
    }
}
