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
    @Dependency private var librarySession: StallyLibrarySession
    @Parameter(title: "Stally File")
    var file: IntentFile

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let session = librarySession.writer
        let archive: TransferArchive
        if let url = file.fileURL {
            archive = try await TransferFileOperations.read(url)
        } else {
            archive = try await TransferFileOperations.readRecords(file.data)
        }
        try Task.checkCancellation()
        try session.checkCurrent()
        guard librarySession.importReview == nil else {
            throw StallyIntentError(message: String(localized: "Finish the current import review first."))
        }
        let review: TransferReview
        do {
            review = try await TransferOperations.prepareReview(archive, context: ModelContext(container))
        } catch {
            throw StallyIntentError(message: error.localizedDescription)
        }
        try Task.checkCancellation()
        try session.checkCurrent()
        guard librarySession.importReview == nil else {
            throw StallyIntentError(message: String(localized: "Finish the current import review first."))
        }
        librarySession.importReview = review
        return .result(dialog: "Review the file in Stally. Nothing has been imported yet.")
    }
}
