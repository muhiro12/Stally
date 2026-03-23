import Foundation
import StallyLibrary
import SwiftData

enum StallyBackupWorkflow {
    static func prepareExport(
        items: [Item]
    ) -> StallyBackupCenterState.ExportPreparation {
        let preparation = StallyBackupFileAdapter.prepareExport(items: items)

        return .init(
            snapshot: preparation.snapshot,
            document: preparation.document,
            filename: preparation.filename
        )
    }

    static func makeImportPreview(
        from url: URL,
        existingItemIDs: Set<UUID>
    ) throws -> StallyBackupCenterState.ImportPreview {
        do {
            let payload = try StallyBackupFileAdapter.loadImportPayload(
                from: url,
                existingItemIDs: existingItemIDs
            )

            return .init(
                sourceURL: payload.sourceURL,
                analysis: payload.analysis
            )
        } catch let error as DecodingError {
            throw StallyTransferOperationError.wrapping(
                error,
                operation: .importPreview,
                phase: .decode,
                fallbackDescription: StallyLocalization.string(
                    "Stally couldn't read this backup file."
                )
            )
        } catch {
            throw StallyTransferOperationError.wrapping(
                error,
                operation: .importPreview,
                phase: .fileAccess,
                fallbackDescription: StallyLocalization.string(
                    "Stally couldn't read this backup file."
                )
            )
        }
    }

    static func mergeImport(
        context: ModelContext,
        preview: StallyBackupCenterState.ImportPreview
    ) throws -> StallyBackupImportResult {
        do {
            return try StallyAppActionService.mergeImport(
                context: context,
                snapshot: preview.analysis.snapshot
            )
        } catch let error as StallyBackupImportValidationError {
            throw StallyTransferOperationError.wrapping(
                error,
                operation: .mergeImport,
                phase: .preflight,
                fallbackDescription: StallyLocalization.string(
                    "Stally couldn't merge this backup."
                )
            )
        } catch {
            throw StallyTransferOperationError.wrapping(
                error,
                operation: .mergeImport,
                phase: .mutation,
                fallbackDescription: StallyLocalization.string(
                    "Stally couldn't merge this backup."
                )
            )
        }
    }

    static func replaceImport(
        context: ModelContext,
        preview: StallyBackupCenterState.ImportPreview
    ) throws -> StallyBackupImportResult {
        do {
            return try StallyAppActionService.replaceImport(
                context: context,
                snapshot: preview.analysis.snapshot
            )
        } catch let error as StallyBackupImportValidationError {
            throw StallyTransferOperationError.wrapping(
                error,
                operation: .replaceImport,
                phase: .preflight,
                fallbackDescription: StallyLocalization.string(
                    "Stally couldn't replace the current library."
                )
            )
        } catch {
            throw StallyTransferOperationError.wrapping(
                error,
                operation: .replaceImport,
                phase: .mutation,
                fallbackDescription: StallyLocalization.string(
                    "Stally couldn't replace the current library."
                )
            )
        }
    }

    static func deleteAllItems(
        context: ModelContext
    ) throws {
        do {
            try StallyAppActionService.deleteAllItems(
                context: context
            )
        } catch {
            throw StallyTransferOperationError.wrapping(
                error,
                operation: .deleteAll,
                phase: .mutation,
                fallbackDescription: StallyLocalization.string(
                    "Stally couldn't delete the current library."
                )
            )
        }
    }
}
