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
    @Parameter(
        title: "Include Photos",
        description: "Exported photos retain embedded metadata, including location when present.",
        default: true
    )
    var includingImages: Bool

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let archive = try IntentAccess.read(container: container) { context in
            try TransferOperations.export(context: context, includingImages: includingImages)
        }
        let url = try await TransferFileOperations.writeTemporary(archive)
        var file = IntentFile(
            fileURL: url,
            filename: StallyExportDocument.filename() + ".stally",
            type: StallyExportDocument.contentType
        )
        file.removedOnCompletion = true
        return .result(value: file)
    }
}
