import AppIntents
import Foundation
import StallyLibrary
import SwiftData
import UniformTypeIdentifiers

struct GetPhotoFileIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Photo File"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Get Photo File") {
            \.$photo
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Photo")
    var photo: PhotoEntity

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<IntentFile> {
        let value = try IntentAccess.read(container: container) { context in
            let record = try IntentRecordLookup.record(ItemPhoto.self, uuid: photo.id, context: context) { $0.uuid }
            guard let data = record.imageData else { throw RecordError.missingRecord }
            let type = try PhotoOperations.contentType(of: data)
            guard let fileExtension = type.preferredFilenameExtension else { throw RecordError.invalidPhoto }
            return IntentFile(data: data, filename: "\(record.uuid.uuidString).\(fileExtension)", type: type)
        }
        return .result(value: value)
    }
}
