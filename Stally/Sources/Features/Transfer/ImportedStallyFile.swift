import CoreTransferable
import StallyLibrary
import UniformTypeIdentifiers

/// Decode while the provider's temporary file is accessible; review owns only the bounded snapshot.
struct ImportedStallyFile: Transferable {
    enum Contents: Sendable {
        case archive(TransferArchive)
        case failure(String)
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: StallyExportDocument.contentType) { received in
            await read(received.file)
        }
        FileRepresentation(importedContentType: .json) { received in
            await read(received.file)
        }
    }

    let contents: Contents

    private static func read(_ url: URL) async -> Self {
        do {
            return try await .init(contents: .archive(TransferFileOperations.read(url)))
        } catch {
            // Keep validation failures visible instead of silently dropping an undecodable provider item.
            return .init(contents: .failure(error.localizedDescription))
        }
    }
}
