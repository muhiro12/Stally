import AppIntents
import StallyLibrary
import SwiftData
import UniformTypeIdentifiers

struct ExportRecordsIntent: AppIntent {
    static let title: LocalizedStringResource = "Export Records as JSON"
    static let description = IntentDescription(
        """
        Export records as JSON for use in other apps. Image files are not included. \
        For import into Stally, use the file promptly after export. \
        Future versions may not support older files.
        """
    )
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }

    @Dependency private var container: ModelContainer

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let archive = try await TransferOperations.prepareExport(
            context: ModelContext(container),
            includingImages: false
        )
        let url = try await TransferFileOperations.writeTemporaryRecords(archive)
        var file = IntentFile(fileURL: url, filename: StallyExportDocument.filename() + ".json", type: .json)
        file.removedOnCompletion = true
        return .result(value: file)
    }
}
