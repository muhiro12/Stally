import StallyLibrary
import SwiftUI
import UniformTypeIdentifiers

final class StallyExportDocument: WritableDocument {
    static let contentType = UTType(exportedAs: StallyDataContract.fileTypeIdentifier, conformingTo: .package)
    static var writableContentTypes: [UTType] { [contentType] }
    let archive: TransferArchive

    init(archive: TransferArchive) {
        self.archive = archive
    }

    nonisolated func writer(configuration: sending WriteConfiguration)
    -> sending FileWrapperDocumentWriter<TransferArchive> {
        FileWrapperDocumentWriter(configuration) { snapshot, _ in
            try snapshot.fileWrapper()
        }
    }

    func snapshot(contentType _: UTType) -> sending TransferArchive {
        archive
    }
}
