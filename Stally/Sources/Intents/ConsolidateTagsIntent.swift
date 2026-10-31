import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct ConsolidateTagsIntent: AppIntent {
    static let title: LocalizedStringResource = "Consolidate Tags"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Consolidate Tags") {
            \.$source
            \.$survivor
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Source")
    var source: TagEntity
    @Parameter(title: "Survivor")
    var survivor: TagEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        let review = try IntentAccess.read(container: container) { context in
            let sourceTag = try IntentRecordLookup.record(
                StallyLibrary.Tag.self,
                uuid: source.id,
                context: context,
                identity: \.uuid
            )
            let survivorTag = try IntentRecordLookup.record(
                StallyLibrary.Tag.self,
                uuid: survivor.id,
                context: context
            ) { $0.uuid }
            return try TagOperations.reviewConsolidation(source: sourceTag, survivor: survivorTag, context: context)
        }
        let count = review.affectedItemIDs.count
        try await requestConfirmation(
            dialog: "Consolidate \(review.sourceName) into \(review.survivorName)? \(count) Items."
        )
        try await IntentAccess.write(container: container, updates: updates) { context in
            try TagOperations.consolidate(review, context: context)
        }
        return .result()
    }
}
