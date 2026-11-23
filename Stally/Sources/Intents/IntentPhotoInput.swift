import AppIntents
import StallyLibrary

enum IntentPhotoInput {
    static func prepare(_ file: IntentFile) async throws -> PreparedPhoto {
        do {
            if let url = file.fileURL {
                let accessible = url.startAccessingSecurityScopedResource()
                defer { if accessible { url.stopAccessingSecurityScopedResource() } }
                return try await PhotoOperations.prepare(fileURL: url)
            }
            return try await PhotoOperations.prepare(data: file.data)
        } catch { throw StallyIntentError(message: error.localizedDescription) }
    }
}
