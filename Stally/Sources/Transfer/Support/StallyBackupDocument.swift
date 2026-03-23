import Foundation
import StallyLibrary
import SwiftUI
import UniformTypeIdentifiers

struct StallyBackupDocument: FileDocument {
    static let placeholder = Self(
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

        snapshot = try StallyBackupFileAdapter.decodeSnapshot(from: data)
    }

    func fileWrapper(
        configuration _: WriteConfiguration
    ) throws -> FileWrapper {
        .init(
            regularFileWithContents: try StallyBackupFileAdapter.encodeData(
                for: snapshot
            )
        )
    }
}

extension UTType {
    nonisolated static let stallyBackup = UTType(
        exportedAs: "com.muhiro12.stally.backup",
        conformingTo: .json
    )
}
