import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct ExportLibraryIntent: AppIntent {
    static let title: LocalizedStringResource = "Export Stally Library"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Export Stally Library") {
            \.$includingImages
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Include Photos", default: true)
    var includingImages: Bool

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let archive = try IntentAccess.read(container: container) { context in
            try TransferOperations.export(context: context, includingImages: includingImages)
        }
        let url = try await TransferFileOperations.writeTemporary(archive)
        var file = IntentFile(fileURL: url, filename: "Stally.stally", type: StallyExportDocument.contentType)
        file.removedOnCompletion = true
        return .result(value: file)
    }
}
