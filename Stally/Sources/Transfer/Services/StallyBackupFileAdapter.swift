import Foundation
import StallyLibrary

enum StallyBackupFileAdapter {
    struct ExportPreparation {
        let snapshot: StallyBackupSnapshot
        let document: StallyBackupDocument
        let filename: String
    }

    struct ImportPayload {
        let sourceURL: URL
        let analysis: StallyBackupImportAnalysis
    }

    static func prepareExport(
        items: [Item],
        exportedAt: Date = .now
    ) -> ExportPreparation {
        let snapshot = StallyBackupCodec.snapshot(
            from: items,
            exportedAt: exportedAt
        )

        return .init(
            snapshot: snapshot,
            document: .init(snapshot: snapshot),
            filename: exportFilename(for: snapshot.exportedAt)
        )
    }

    nonisolated static func encodeData(
        for snapshot: StallyBackupSnapshot
    ) throws -> Data {
        try StallyBackupCodec.encode(snapshot)
    }

    nonisolated static func decodeSnapshot(
        from data: Data
    ) throws -> StallyBackupSnapshot {
        try StallyBackupCodec.decode(data)
    }

    static func loadImportPayload(
        from url: URL,
        existingItemIDs: Set<UUID>
    ) throws -> ImportPayload {
        let snapshot = try loadSnapshot(from: url)
        let analysis = StallyBackupImportAnalyzer.analyze(
            snapshot: snapshot,
            existingItemIDs: existingItemIDs
        )

        return .init(
            sourceURL: url,
            analysis: analysis
        )
    }

    nonisolated static func exportFilename(
        for date: Date
    ) -> String {
        "stally-backup-\(backupTimestampFormatter.string(from: date))"
    }
}

private extension StallyBackupFileAdapter {
    nonisolated static var backupTimestampFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter
    }

    static func loadSnapshot(
        from url: URL
    ) throws -> StallyBackupSnapshot {
        try withSecurityScopedResource(for: url) {
            let data = try Data(contentsOf: url)
            return try decodeSnapshot(from: data)
        }
    }

    static func withSecurityScopedResource<T>(
        for url: URL,
        perform operation: () throws -> T
    ) throws -> T {
        let accessedSecurityScope = url.startAccessingSecurityScopedResource()

        defer {
            if accessedSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }
}
