import Foundation
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
        state.beginExport(
            StallyBackupWorkflow.prepareExport(
                items: items
            )
        )
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
                state.recordImportFailure(
                    error,
                    operation: .importPreview,
                    phase: .fileAccess,
                    fallback: StallyLocalization.string(
                        "Stally couldn't read this backup file."
                    )
                )
            }
        case .failure(let error as CocoaError)
                where error.code == .userCancelled:
            state.importStatus = nil
        case .failure(let error):
            state.recordImportFailure(
                error,
                operation: .importPreview,
                phase: .fileAccess,
                fallback: StallyLocalization.string(
                    "Stally couldn't open the import picker."
                )
            )
        }
    }

    func mergeImport(
        _ preview: StallyBackupCenterState.ImportPreview
    ) {
        do {
            let result = try StallyBackupWorkflow.mergeImport(
                context: context,
                preview: preview
            )
            state.recordMerge(
                preview: preview,
                result: result
            )
        } catch {
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
        do {
            let result = try StallyBackupWorkflow.replaceImport(
                context: context,
                preview: preview
            )
            state.recordReplace(
                preview: preview,
                result: result
            )
        } catch {
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
        do {
            try StallyBackupWorkflow.deleteAllItems(
                context: context
            )
            state.recordDeleteAllSuccess()
        } catch {
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
