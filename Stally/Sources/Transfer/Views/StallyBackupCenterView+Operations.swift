import Foundation
import MHPlatform
import StallyLibrary
import SwiftUI

extension StallyBackupCenterView {
    @ViewBuilder
    var importPreviewArea: some View {
        if let summary = state.importExecutionSummary {
            StallyBackupImportExecutionSummaryCard(
                summary: summary,
                usesCompactLayout: usesCompactLayout
            )
        }

        if let preview = state.importPreview {
            StallyBackupImportPreviewCard(
                preview: preview,
                usesCompactLayout: usesCompactLayout,
                onMerge: {
                    mergeImport(preview)
                },
                onReplace: {
                    state.isReplaceConfirmationPresented = true
                }
            )
        }
    }

    var importSupportingText: String {
        StallyLocalization.string(
            """
        Preview shows the snapshot contents, overlap with local items,
        and any warnings before import actions are enabled.
        """
        )
    }

    func startExport() {
        let preparation = StallyBackupWorkflow.prepareExport(
            items: items
        )
        backupLogger.notice(
            "backup export prepared",
            metadata: [
                "itemCount": "\(items.count)",
                "markCount": "\(totalMarks)",
                "filename": preparation.filename
            ]
        )
        state.beginExport(preparation)
    }

    func handleExportResult(
        _ result: Result<URL, any Error>
    ) {
        state.recordExportResult(result)

        switch result {
        case .success(let url):
            backupLogger.notice(
                "backup export completed",
                metadata: [
                    "itemCount": "\(items.count)",
                    "markCount": "\(totalMarks)",
                    "filename": url.lastPathComponent
                ]
            )
        case .failure(let error as CocoaError)
                where error.code == .userCancelled:
            break
        case .failure(let error):
            backupLogger.error(
                "backup export failed",
                metadata: transferFailureMetadata(
                    error,
                    operation: .export,
                    phase: .fileAccess
                )
            )
        }
    }

    func handleImportSelection(
        _ result: Result<[URL], any Error>
    ) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                state.importPreview = nil
                return
            }

            do {
                state.recordImportPreview(
                    try StallyBackupWorkflow.makeImportPreview(
                        from: url,
                        existingItemIDs: Set(items.map(\.id))
                    )
                )
            } catch {
                logImportPreviewFailure(
                    error,
                    sourceName: url.lastPathComponent
                )
                state.recordImportPreviewFailure(
                    error,
                    fallback: StallyLocalization.string(
                        "Stally couldn't read this backup file."
                    )
                )
            }
        case .failure(let error as CocoaError)
                where error.code == .userCancelled:
            state.importStatus = nil
        case .failure(let error):
            logImportPreviewFailure(error)
            state.recordImportPreviewFailure(
                error,
                fallback: StallyLocalization.string(
                    "Stally couldn't open the import picker."
                )
            )
        }
    }

    func mergeImport(
        _ preview: StallyBackupCenterState.ImportPreview
    ) {
        backupLogger.notice(
            "backup merge started",
            metadata: importPreviewMetadata(preview)
        )

        do {
            let result = try StallyBackupWorkflow.mergeImport(
                context: context,
                preview: preview
            )
            backupLogger.notice(
                "backup merge completed",
                metadata: importResultMetadata(
                    result,
                    mode: "merge",
                    sourceName: preview.sourceName
                )
            )
            state.recordMerge(
                preview: preview,
                result: result
            )
        } catch {
            backupLogger.error(
                "backup merge failed",
                metadata: transferFailureMetadata(
                    error,
                    operation: .mergeImport,
                    phase: .mutation,
                    extra: importPreviewMetadata(preview)
                )
            )
            state.recordImportFailure(
                error,
                operation: .mergeImport,
                phase: .mutation,
                fallback: StallyLocalization.string(
                    "Stally couldn't merge this backup."
                ),
                preservePreview: true
            )
        }
    }

    func replaceImport(
        _ preview: StallyBackupCenterState.ImportPreview
    ) {
        backupLogger.notice(
            "backup replace started",
            metadata: importPreviewMetadata(preview)
        )

        do {
            let result = try StallyBackupWorkflow.replaceImport(
                context: context,
                preview: preview
            )
            backupLogger.notice(
                "backup replace completed",
                metadata: importResultMetadata(
                    result,
                    mode: "replace",
                    sourceName: preview.sourceName
                )
            )
            state.recordReplace(
                preview: preview,
                result: result
            )
        } catch {
            backupLogger.error(
                "backup replace failed",
                metadata: transferFailureMetadata(
                    error,
                    operation: .replaceImport,
                    phase: .mutation,
                    extra: importPreviewMetadata(preview)
                )
            )
            state.recordImportFailure(
                error,
                operation: .replaceImport,
                phase: .mutation,
                fallback: StallyLocalization.string(
                    "Stally couldn't replace the current library."
                ),
                preservePreview: true
            )
        }
    }

    func deleteAllItems() {
        backupLogger.notice(
            "library delete-all started",
            metadata: [
                "itemCount": "\(items.count)",
                "markCount": "\(totalMarks)"
            ]
        )

        do {
            try StallyBackupWorkflow.deleteAllItems(
                context: context
            )
            backupLogger.notice(
                "library delete-all completed",
                metadata: [
                    "deletedItems": "\(items.count)",
                    "deletedMarks": "\(totalMarks)"
                ]
            )
            state.recordDeleteAllSuccess()
        } catch {
            backupLogger.error(
                "library delete-all failed",
                metadata: transferFailureMetadata(
                    error,
                    operation: .deleteAll,
                    phase: .mutation,
                    extra: [
                        "itemCount": "\(items.count)",
                        "markCount": "\(totalMarks)"
                    ]
                )
            )
            state.recordImportFailure(
                error,
                operation: .deleteAll,
                phase: .mutation,
                fallback: StallyLocalization.string(
                    "Stally couldn't delete the current library."
                )
            )
        }
    }
}

private extension StallyBackupCenterView {
    var backupLogger: MHLogger {
        assembly.logging.logger(category: "Backup")
    }

    func importPreviewMetadata(
        _ preview: StallyBackupCenterState.ImportPreview
    ) -> [String: String] {
        let summary = preview.analysis.summary

        return [
            "sourceName": preview.sourceName,
            "totalItems": "\(summary.totalItems)",
            "archivedItems": "\(summary.archivedItems)",
            "totalMarks": "\(summary.totalMarks)",
            "existingItems": "\(summary.existingItems)",
            "newItems": "\(summary.newItems)"
        ]
    }

    func logImportPreviewFailure(
        _ error: any Error,
        sourceName: String? = nil
    ) {
        var extra: [String: String] = [:]

        if let sourceName {
            extra["sourceName"] = sourceName
        }

        backupLogger.error(
            "backup import preview failed",
            metadata: transferFailureMetadata(
                error,
                operation: .importPreview,
                phase: .fileAccess,
                extra: extra
            )
        )
    }

    func importResultMetadata(
        _ result: StallyBackupImportResult,
        mode: String,
        sourceName: String
    ) -> [String: String] {
        let summary = result.analysis.summary

        return [
            "mode": mode,
            "sourceName": sourceName,
            "totalItems": "\(summary.totalItems)",
            "totalMarks": "\(summary.totalMarks)",
            "deletedItems": "\(result.deletedItems)",
            "createdItems": "\(result.createdItems)",
            "updatedItems": "\(result.updatedItems)",
            "insertedMarks": "\(result.insertedMarks)",
            "skippedMarks": "\(result.skippedMarks)"
        ]
    }

    func transferFailureMetadata(
        _ error: any Error,
        operation: StallyTransferOperationError.Operation,
        phase: StallyTransferFailurePhase,
        extra: [String: String] = [:]
    ) -> [String: String] {
        let transferError = StallyTransferOperationError.wrapping(
            error,
            operation: operation,
            phase: phase,
            fallbackDescription: ""
        )
        var metadata = extra

        metadata["operation"] = transferError.operation.rawValue
        metadata["phase"] = transferError.phase.rawValue
        metadata["error"] = String(
            describing: transferError.underlyingError
        )

        return metadata
    }
}
