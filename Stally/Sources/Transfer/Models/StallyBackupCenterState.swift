import Foundation
import StallyLibrary

struct StallyBackupCenterState {
    enum ImportExecutionMode {
        case merge
        case replace
    }

    struct ImportPreview {
        let sourceURL: URL
        let analysis: StallyBackupImportAnalysis

        var sourceName: String {
            sourceURL.lastPathComponent
        }
    }

    struct ImportExecutionSummary {
        let mode: ImportExecutionMode
        let sourceName: String
        let result: StallyBackupImportResult

        var title: String {
            switch mode {
            case .merge:
                StallyLocalization.string("Last Merge Result")
            case .replace:
                StallyLocalization.string("Last Replace Result")
            }
        }
    }

    var exportDocument: StallyBackupDocument?
    var isExporting = false
    var exportFilename = exportFilename(for: .now)
    var exportStatusMessage: String?
    var isImporting = false
    var importPreview: ImportPreview?
    var importStatusMessage: String?
    var importExecutionSummary: ImportExecutionSummary?
    var isReplaceConfirmationPresented = false
    var isDeleteAllConfirmationPresented = false

    mutating func beginExport(
        snapshot: StallyBackupSnapshot
    ) {
        exportDocument = .init(snapshot: snapshot)
        exportFilename = Self.exportFilename(
            for: snapshot.exportedAt
        )
        isExporting = true
    }

    mutating func recordExportResult(
        _ result: Result<URL, any Error>
    ) {
        switch result {
        case .success(let url):
            exportStatusMessage = StallyLocalization.format(
                "Backup saved as %@.",
                url.lastPathComponent
            )
        case .failure(let error as CocoaError)
                where error.code == .userCancelled:
            exportStatusMessage = nil
        case .failure(let error):
            exportStatusMessage = (error as? LocalizedError)?.errorDescription
                ?? StallyLocalization.string("Stally couldn't export this backup.")
        }
    }

    mutating func recordImportPreview(
        _ preview: ImportPreview
    ) {
        importPreview = preview
    }

    mutating func recordImportFailure(
        _ error: any Error,
        fallback: String
    ) {
        importPreview = nil
        importStatusMessage = (error as? LocalizedError)?.errorDescription
            ?? fallback
    }

    mutating func recordMerge(
        preview: ImportPreview,
        result: StallyBackupImportResult
    ) {
        importExecutionSummary = .init(
            mode: .merge,
            sourceName: preview.sourceName,
            result: result
        )
        importPreview = nil
        importStatusMessage = StallyLocalization.format(
            "Merged %@ into the current library.",
            preview.sourceName
        )
    }

    mutating func recordReplace(
        preview: ImportPreview,
        result: StallyBackupImportResult
    ) {
        importExecutionSummary = .init(
            mode: .replace,
            sourceName: preview.sourceName,
            result: result
        )
        importPreview = nil
        importStatusMessage = StallyLocalization.format(
            "Replaced the current library with %@.",
            preview.sourceName
        )
    }

    mutating func recordDeleteAllSuccess() {
        importPreview = nil
        importExecutionSummary = nil
        importStatusMessage = StallyLocalization.string(
            "Deleted every item from the current library."
        )
    }
}

private extension StallyBackupCenterState {
    static var backupTimestampFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter
    }

    static func exportFilename(
        for date: Date
    ) -> String {
        "stally-backup-\(backupTimestampFormatter.string(from: date))"
    }
}
