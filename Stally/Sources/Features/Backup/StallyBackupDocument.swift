//
//  StallyBackupDocument.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct StallyBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.stallyBackup]
    }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) {
        data = configuration.file.regularFileContents ?? .init()
    }

    func fileWrapper(configuration _: WriteConfiguration) -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

extension UTType {
    nonisolated static var stallyBackup: UTType {
        .init(
            exportedAs: "com.muhiro12.stally.backup",
            conformingTo: .json
        )
    }
}
