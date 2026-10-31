import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct AssignTagsIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Item Tags"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Set Item Tags") {
            \.$item
            \.$tags
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity
    @Parameter(title: "Tags")
    var tags: [TagEntity]

    @MainActor
    func perform() async throws -> some IntentResult {
        try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            let assigned = try tags.map { tag in
                try IntentRecordLookup.record(StallyLibrary.Tag.self, uuid: tag.id, context: context) { $0.uuid }
            }
            try TagOperations.assign(assigned, to: record, context: context)
        }
        return .result()
    }
}
