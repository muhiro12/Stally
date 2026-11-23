import CoreTransferable
import StallyLibrary
import UniformTypeIdentifiers

struct ImportedPhoto: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            let attachment = try await PhotoOperations.prepare(fileURL: received.file)
            return Self(prepared: attachment)
        }
    }
    let prepared: PreparedPhoto
}
