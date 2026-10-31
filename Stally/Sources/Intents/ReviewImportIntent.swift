import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct ReviewImportIntent: AppIntent {
    static let title: LocalizedStringResource = "Review Stally Import"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .foreground }
    static var parameterSummary: some ParameterSummary {
        Summary("Review Stally Import") {
            \.$file
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Dependency private var presentation: TransferPresentation
    @Parameter(title: "Stally File")
    var file: IntentFile

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let archive: TransferArchive
        if let url = file.fileURL {
            archive = try await TransferFileOperations.read(url)
        } else {
            archive = try await TransferFileOperations.readRecords(file.data)
        }
        try Task.checkCancellation()
        guard presentation.review == nil else {
            throw StallyIntentError(message: String(localized: "Finish the current import review first."))
        }
        presentation.review = try IntentAccess.read(container: container) { context in
            try TransferOperations.review(archive, context: context)
        }
        return .result(dialog: "Review the file in Stally. Nothing has been imported yet.")
    }
}
