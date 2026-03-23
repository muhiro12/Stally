import Foundation
import StallyLibrary

struct StallyBackupCenterState {
    enum StatusPresentation {
        case message(String)
        case failure(StallyTransferOperationError)

        var messageText: String {
            switch self {
            case .message(let message):
                message
            case .failure(let error):
                error.errorDescription
                    ?? StallyLocalization.string(
                        "Stally couldn't complete this backup operation."
                    )
            }
        }

        var failure: StallyTransferOperationError? {
            switch self {
            case .message:
                nil
            case .failure(let error):
                error
            }
        }
    }

    enum ImportExecutionMode {
        case merge
        case replace
    }

    struct ExportPreparation {
        let snapshot: StallyBackupSnapshot
        let document: StallyBackupDocument
        let filename: String
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
    var exportFilename = StallyBackupFileAdapter.exportFilename(for: .now)
    var exportStatus: StatusPresentation?
    var isImporting = false
    var importPreview: ImportPreview?
    var importStatus: StatusPresentation?
    var importExecutionSummary: ImportExecutionSummary?
    var isReplaceConfirmationPresented = false
    var isDeleteAllConfirmationPresented = false

    mutating func beginExport(
        _ preparation: ExportPreparation
    ) {
        exportDocument = preparation.document
        exportFilename = preparation.filename
        exportStatus = nil
        isExporting = true
    }

    mutating func recordExportResult(
        _ result: Result<URL, any Error>
    ) {
        switch result {
        case .success(let url):
            exportStatus = .message(
                StallyLocalization.format(
                    "Backup saved as %@.",
                    url.lastPathComponent
                )
            )
        case .failure(let error as CocoaError)
                where error.code == .userCancelled:
            exportStatus = nil
        case .failure(let error):
            exportStatus = .failure(
                StallyTransferOperationError.wrapping(
                    error,
                    operation: .export,
                    phase: .fileAccess,
                    fallbackDescription: StallyLocalization.string(
                        "Stally couldn't export this backup."
                    )
                )
            )
        }
    }

    mutating func recordImportPreview(
        _ preview: ImportPreview
    ) {
        importPreview = preview
        importStatus = nil
    }

    mutating func recordImportPreviewFailure(
        _ error: any Error,
        fallback: String
    ) {
        recordImportFailure(
            error,
            operation: .importPreview,
            phase: .fileAccess,
            fallback: fallback,
            preservePreview: true
        )
    }

    mutating func recordImportFailure(
        _ error: any Error,
        operation: StallyTransferOperationError.Operation,
        phase: StallyTransferFailurePhase,
        fallback: String,
        preservePreview: Bool = false
    ) {
        if !preservePreview {
            importPreview = nil
        }

        importStatus = .failure(
            StallyTransferOperationError.wrapping(
                error,
                operation: operation,
                phase: phase,
                fallbackDescription: fallback
            )
        )
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
        importStatus = .message(
            StallyLocalization.format(
                "Merged %@ into the current library.",
                preview.sourceName
            )
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
        importStatus = .message(
            StallyLocalization.format(
                "Replaced the current library with %@.",
                preview.sourceName
            )
        )
    }

    mutating func recordDeleteAllSuccess() {
        importPreview = nil
        importExecutionSummary = nil
        importStatus = .message(
            StallyLocalization.string(
                "Deleted every item from the current library."
            )
        )
    }
}
