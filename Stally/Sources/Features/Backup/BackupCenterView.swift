//
//  BackupCenterView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct BackupCenterView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Item.createdAt, order: .reverse)
    private var items: [Item]

    let incomingFile: StallyImportFile?

    @State private var exportDocument: StallyBackupDocument?
    @State private var isPresentingImporter = false
    @State private var isConfirmingMerge = false
    @State private var isConfirmingReplace = false
    @State private var isConfirmingDeleteEverything = false
    @State private var selectedReview: BackupImportReview?
    @State private var pendingReview: BackupImportReview?

    @State private var statusMessage: String?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isPresentingAlert = false
    @State private var isReplacingExistingItems = false

    private var summary: BackupCollectionSummary {
        .init(items: items)
    }

    var body: some View {
        BackupList(
            summary: summary,
            preview: selectedReview?.preview,
            isReplacingExistingItems: $isReplacingExistingItems,
            statusMessage: statusMessage,
            exportAction: exportBackup,
            chooseBackupAction: chooseBackupFile,
            mergeAction: confirmMerge,
            replaceAction: confirmReplace,
            deleteEverythingAction: confirmDeleteEverything
        )
        .navigationTitle("Import & Export")
        .onChange(of: isReplacingExistingItems) {
            refreshSelectedReview()
        }
        .onChange(of: incomingFile?.id, initial: true) {
            if let incomingFile {
                selectImport(incomingFile)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StallyLinkShareButton(
                    link: .destination(.backupCenter),
                    title: "Share Import & Export Link"
                )
            }
        }
        .sheet(item: $exportDocument) { document in
            BackupExportView(document: document)
        }
        .fileImporter(
            isPresented: $isPresentingImporter,
            allowedContentTypes: [.stallyBackup]
        ) { result in
            handleImportResult(result)
        }
        .confirmationDialog(
            "Merge Into Library?",
            isPresented: $isConfirmingMerge,
            titleVisibility: .visible
        ) {
            Button("Merge Into Library") {
                mergeIntoLibrary()
            }

            Button("Cancel", role: .cancel) {
                cancelImportConfirmation()
            }
        } message: {
            Text("Merge import will preserve local items and add missing history.")
        }
        .confirmationDialog(
            "Replace Library?",
            isPresented: $isConfirmingReplace,
            titleVisibility: .visible
        ) {
            Button("Replace Library", role: .destructive) {
                replaceLibrary()
            }

            Button("Cancel", role: .cancel) {
                cancelImportConfirmation()
            }
        } message: {
            Text(
                """
                This replaces every Item, including Archive, and their notes, photos, \
                starts, and Marks with this file.
                """
            )
            Text("Keep one recent export before you try any replace-style restore.")
        }
        .confirmationDialog(
            "Delete Every Item?",
            isPresented: $isConfirmingDeleteEverything,
            titleVisibility: .visible
        ) {
            Button("Delete Every Item", role: .destructive) {
                deleteEverything()
            }

            Button("Cancel", role: .cancel) {
                isConfirmingDeleteEverything = false
            }
        } message: {
            Text("Delete Everything intentionally creates an empty library. Export before higher-risk changes.")
        }
        .alert(alertTitle, isPresented: $isPresentingAlert) {
            Button("OK", role: .cancel) {
                isPresentingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }

    init() {
        incomingFile = nil
    }

    init(incomingFile: StallyImportFile?) {
        self.incomingFile = incomingFile
    }
}

private extension BackupCenterView {
    private func exportBackup() {
        exportDocument = nil
        statusMessage = nil

        do {
            let data = try BackupOperations.exportData(for: items, exportedAt: StallyActionDate.current)
            exportDocument = .init(data: data)
        } catch BackupError.validationFailed(let preview) {
            presentError(
                title: String(localized: "Data could not be exported."),
                message: preview.validationIssues.map { issue in
                    String(localized: issue.title)
                }
                .joined(separator: "\n")
            )
        } catch {
            presentError(
                title: String(localized: "Data could not be exported."),
                message: error.localizedDescription
            )
        }
    }

    private func chooseBackupFile() {
        isPresentingImporter = true
    }

    private func handleImportResult(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let url):
            readBackupFile(at: url)
        case .failure(let error):
            presentError(
                title: String(localized: "Data file could not be opened."),
                message: error.localizedDescription
            )
        }
    }

    private func readBackupFile(at url: URL) {
        do {
            selectImport(try .read(at: url))
        } catch {
            cancelImportConfirmation()
            selectedReview = nil
            presentError(
                title: String(localized: "Data file could not be read."),
                message: error.localizedDescription
            )
        }
    }

    private func selectImport(_ file: StallyImportFile) {
        cancelImportConfirmation()
        selectedReview = BackupOperations.review(
            data: file.data,
            currentItems: items,
            replacingExistingItems: isReplacingExistingItems
        )
        statusMessage = nil
    }

    private func confirmMerge() {
        if hasCurrentReview() {
            pendingReview = selectedReview
            isConfirmingMerge = true
        }
    }

    private func confirmReplace() {
        if hasCurrentReview() {
            pendingReview = selectedReview
            isConfirmingReplace = true
        }
    }

    private func hasCurrentReview() -> Bool {
        guard let selectedReview else {
            return false
        }
        let refreshed = BackupOperations.review(
            data: selectedReview.data,
            currentItems: items,
            replacingExistingItems: isReplacingExistingItems
        )
        guard refreshed == selectedReview else {
            requireFreshReview(refreshed)
            return false
        }
        return refreshed.preview.canImport
    }

    private func confirmDeleteEverything() {
        isConfirmingDeleteEverything = true
    }

    private func refreshSelectedReview() {
        cancelImportConfirmation()
        guard let selectedReview else {
            return
        }
        self.selectedReview = BackupOperations.review(
            data: selectedReview.data,
            currentItems: items,
            replacingExistingItems: isReplacingExistingItems
        )
    }

    private func mergeIntoLibrary() {
        importSelectedReview()
    }

    private func replaceLibrary() {
        importSelectedReview()
    }

    private func importSelectedReview() {
        guard let pendingReview, pendingReview == selectedReview else {
            return
        }
        cancelImportConfirmation()
        do {
            let result = try BackupOperations.importReviewed(pendingReview, context: modelContext)
            self.selectedReview = nil
            statusMessage = importStatusMessage(
                prefix: result.didReplaceLibrary
                    ? String(localized: "Replaced the current library.")
                    : String(localized: "Merged into the current library."),
                result: result
            )
        } catch {
            handleBackupMutationError(error)
        }
    }

    private func deleteEverything() {
        do {
            let result = try BackupOperations.deleteEverything(context: modelContext)
            selectedReview = nil
            statusMessage = deleteStatusMessage(for: result)
        } catch {
            presentError(
                title: String(localized: "Library could not be cleared."),
                message: error.localizedDescription
            )
        }
    }

    private func handleBackupMutationError(_ error: any Error) {
        switch error {
        case BackupError.reviewChanged(let review):
            requireFreshReview(review)
        case BackupError.validationFailed:
            refreshSelectedReview()
            presentError(
                title: String(localized: "Data has validation issues."),
                message: String(localized: "Preview the validation issues before importing this data.")
            )
        default:
            presentError(
                title: String(localized: "Data transfer failed."),
                message: error.localizedDescription
            )
        }
    }

    private func requireFreshReview(_ review: BackupImportReview) {
        cancelImportConfirmation()
        selectedReview = review
        presentError(
            title: String(localized: "Review Updated"),
            message: String(localized: "Your collection changed. Review the updated preview before importing.")
        )
    }

    private func cancelImportConfirmation() {
        isConfirmingMerge = false
        isConfirmingReplace = false
        pendingReview = nil
    }

    private func presentError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        isPresentingAlert = true
    }

    private func importStatusMessage(
        prefix: String,
        result: BackupImportResult
    ) -> String {
        let counts = String(
            localized: "New: \(result.insertedItemCount). Marks Added: \(result.insertedMarkCount)."
        )
        return "\(prefix)\n\(counts)"
    }

    private func deleteStatusMessage(for result: BackupResetResult) -> String {
        let format = String(
            localized: "Deleted every item from the current library.\nItems: %lld. Marks: %lld."
        )
        return String(
            format: format,
            result.deletedItemCount,
            result.deletedMarkCount
        )
    }
}
