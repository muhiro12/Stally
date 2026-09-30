import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// A validated snapshot offered as a file to native sharing services.
struct StallyExportFile: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .stallyBackup) { export in
            let directory = FileManager.default.temporaryDirectory
                .appending(path: "StallyExports", directoryHint: .isDirectory)
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appending(path: "Stally Data.\(BackupOperations.fileExtension)")
            try export.data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }

    let data: Data
}
