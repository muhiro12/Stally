import StallyLibrary
import SwiftUI
import UniformTypeIdentifiers

final class StallyExportDocument: WritableDocument {
    enum Contents: Sendable {
        case package(TransferArchive)
        case records(Data)
    }

    static let contentType = UTType(exportedAs: StallyDataContract.fileTypeIdentifier, conformingTo: .package)
    static var writableContentTypes: [UTType] { [contentType, .json] }

    let contents: Contents

    init(archive: TransferArchive) {
        contents = .package(archive)
    }

    init(records: Data) {
        contents = .records(records)
    }

    static func filename() -> String {
        "Stally-Export-" + Date.now.formatted(.iso8601).replacingOccurrences(of: ":", with: "-")
    }

    nonisolated func writer(configuration: sending WriteConfiguration)
    -> sending FileWrapperDocumentWriter<Contents> {
        FileWrapperDocumentWriter(configuration) { snapshot, _ in
            switch snapshot {
            case .package(let archive):
                try archive.fileWrapper()
            case .records(let data):
                FileWrapper(regularFileWithContents: data)
            }
        }
    }

    func snapshot(contentType _: UTType) -> sending Contents {
        contents
    }
}
