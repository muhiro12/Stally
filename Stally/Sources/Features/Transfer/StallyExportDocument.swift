import StallyLibrary
import SwiftUI
import UniformTypeIdentifiers

final class StallyExportDocument: WritableDocument {
    enum Contents: Sendable {
        case package(TransferArchive)
        case records(TransferArchive)
    }

    struct Writer: DocumentWriter {
        @concurrent
        func write(
            snapshot: sending Contents,
            to destination: URL,
            previous _: sending Contents?,
            progress _: consuming Subprogress
        ) async throws {
            switch snapshot {
            case .package(let archive):
                try await TransferFileOperations.write(archive, to: destination)
            case .records(let archive):
                try await TransferFileOperations.writeRecords(archive, to: destination)
            }
        }
    }

    nonisolated static let contentType = UTType(
        exportedAs: StallyDataContract.fileTypeIdentifier,
        conformingTo: .package
    )
    static var writableContentTypes: [UTType] { [contentType, .json] }

    let contents: Contents

    init(archive: TransferArchive) {
        contents = .package(archive)
    }

    init(records: TransferArchive) {
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

    nonisolated func writer(configuration _: sending WriteConfiguration) -> sending Writer { Writer() }

    func snapshot(contentType _: UTType) -> sending Contents {
        contents
    }
}
