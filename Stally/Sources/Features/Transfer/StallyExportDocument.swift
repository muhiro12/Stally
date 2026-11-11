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
        filename(date: .now, timeZone: .current)
    }

    static func filename(date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ssZ"
        return "Stally-Export-" + formatter.string(from: date)
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
