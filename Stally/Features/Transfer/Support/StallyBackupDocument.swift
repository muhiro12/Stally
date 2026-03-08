import Foundation
import StallyLibrary
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    nonisolated static let stallyBackup = UTType(
        exportedAs: "com.muhiro12.stally.backup",
        conformingTo: .json
    )
}

struct StallyBackupDocument: FileDocument {
    static let placeholder = StallyBackupDocument(
        snapshot: .init(
            exportedAt: .now,
            items: []
        )
    )

    static var readableContentTypes: [UTType] {
        [
            .stallyBackup,
            .json
        ]
    }

    let snapshot: StallyBackupSnapshot

    init(
        snapshot: StallyBackupSnapshot
    ) {
        self.snapshot = snapshot
    }

    init(
        configuration: ReadConfiguration
    ) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        snapshot = try StallyBackupCodec.decode(data)
    }

    func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        .init(
            regularFileWithContents: try StallyBackupCodec.encode(snapshot)
        )
    }
}
