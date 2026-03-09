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
            snapshot: StallyBackupCodec.snapshot(from: items)
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
                    try makeImportPreview(from: url)
                )
            } catch {
                state.recordImportFailure(
                    error,
                    fallback: StallyLocalization.string(
                        "Stally couldn't read this backup file."
                    )
                )
            }
        case .failure(let error as CocoaError)
                where error.code == .userCancelled:
            state.importStatusMessage = nil
        case .failure(let error):
            state.recordImportFailure(
                error,
                fallback: StallyLocalization.string(
                    "Stally couldn't open the import picker."
                )
            )
        }
    }

    func makeImportPreview(
        from url: URL
    ) throws -> StallyBackupCenterState.ImportPreview {
        let accessedSecurityScope = url.startAccessingSecurityScopedResource()

        defer {
            if accessedSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let snapshot = try StallyBackupCodec.decode(data)
        let analysis = StallyBackupImportAnalyzer.analyze(
            snapshot: snapshot,
            existingItemIDs: Set(items.map(\.id))
        )

        return .init(
            sourceURL: url,
            analysis: analysis
        )
    }

    func mergeImport(
        _ preview: StallyBackupCenterState.ImportPreview
    ) {
        do {
            let result = try onMergeImport(preview.analysis.snapshot)
            state.recordMerge(
                preview: preview,
                result: result
            )
        } catch {
            state.recordImportFailure(
                error,
                fallback: StallyLocalization.string(
                    "Stally couldn't merge this backup."
                )
            )
        }
    }

    func replaceImport(
        _ preview: StallyBackupCenterState.ImportPreview
    ) {
        do {
            let result = try onReplaceImport(preview.analysis.snapshot)
            state.recordReplace(
                preview: preview,
                result: result
            )
        } catch {
            state.recordImportFailure(
                error,
                fallback: StallyLocalization.string(
                    "Stally couldn't replace the current library."
                )
            )
        }
    }

    func deleteAllItems() {
        do {
            try onDeleteAll()
            state.recordDeleteAllSuccess()
        } catch {
            state.recordImportFailure(
                error,
                fallback: StallyLocalization.string(
                    "Stally couldn't delete the current library."
                )
            )
        }
    }
}
