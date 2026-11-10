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
    func perform() throws -> some IntentResult & ReturnsValue<IntentFile> {
        let records = try IntentAccess.read(container: container) { context in
            try TransferOperations.exportRecords(context: context)
        }
        let name = StallyExportDocument.filename() + ".json"
        return .result(value: IntentFile(data: records, filename: name, type: .json))
    }
}
