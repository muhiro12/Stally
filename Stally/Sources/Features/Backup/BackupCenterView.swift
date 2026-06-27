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
    @Environment(\.calendar)
    private var calendar

    @Environment(\.modelContext)
    private var modelContext

    let items: [Item]

    @State private var exportDocument: StallyBackupDocument?
    @State private var isPresentingExporter = false
    @State private var isPresentingImporter = false
    @State private var isConfirmingMerge = false
    @State private var isConfirmingReplace = false
    @State private var isConfirmingDeleteEverything = false
    @State private var selectedBackupData: Data?
    @State private var selectedBackupPreview: BackupPreview?
    @State private var statusMessage: String?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isPresentingAlert = false

    private var summary: BackupCollectionSummary {
        .init(items: items)
    }

    var body: some View {
        NavigationStack {
            BackupList(
                summary: summary,
                preview: selectedBackupPreview,
                statusMessage: statusMessage,
                exportAction: exportBackup,
                chooseBackupAction: chooseBackupFile,
                mergeAction: confirmMerge,
                replaceAction: confirmReplace,
                deleteEverythingAction: confirmDeleteEverything
            )
            .navigationTitle("Backup Center")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StallyLinkShareButton(
                        link: .destination(.backupCenter),
                        title: "Share Backup Center Link"
                    )
                }
            }
        }
        .fileExporter(
            isPresented: $isPresentingExporter,
            document: exportDocument,
            contentType: .stallyBackup,
            defaultFilename: String(localized: "Stally Backup")
        ) { result in
            handleExportResult(result)
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
                isConfirmingMerge = false
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
                isConfirmingReplace = false
            }
        } message: {
            Text("Replace import will overwrite them.")
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
}

private extension BackupCenterView {
    private func exportBackup() {
        do {
            let data = try BackupOperations.exportData(for: items)
            exportDocument = .init(data: data)
            isPresentingExporter = true
        } catch {
            presentError(
                title: String(localized: "Backup could not be exported."),
                message: error.localizedDescription
            )
        }
    }

    private func handleExportResult(_ result: Result<URL, any Error>) {
        switch result {
        case .success:
            statusMessage = String(localized: "Backup saved.")
        case .failure(let error):
            presentError(
                title: String(localized: "Backup could not be saved."),
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
                title: String(localized: "Backup file could not be opened."),
                message: error.localizedDescription
            )
        }
    }

    private func readBackupFile(at url: URL) {
        let didAccessSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            selectedBackupData = data
            selectedBackupPreview = BackupOperations.preview(
                data: data,
                currentItems: items,
                calendar: calendar
            )
            statusMessage = nil
        } catch {
            selectedBackupData = nil
            selectedBackupPreview = nil
            presentError(
                title: String(localized: "Backup file could not be read."),
                message: error.localizedDescription
            )
        }
    }

    private func confirmMerge() {
        isConfirmingMerge = true
    }

    private func confirmReplace() {
        isConfirmingReplace = true
    }

    private func confirmDeleteEverything() {
        isConfirmingDeleteEverything = true
    }

    private func mergeIntoLibrary() {
        guard let selectedBackupData else {
            return
        }

        do {
            let result = try BackupOperations.mergeIntoLibrary(
                data: selectedBackupData,
                context: modelContext,
                calendar: calendar
            )
            selectedBackupPreview = nil
            self.selectedBackupData = nil
            statusMessage = importStatusMessage(
                prefix: String(localized: "Merged into the current library."),
                result: result
            )
        } catch {
            handleBackupMutationError(error)
        }
    }

    private func replaceLibrary() {
        guard let selectedBackupData else {
            return
        }

        do {
            let result = try BackupOperations.replaceLibrary(
                data: selectedBackupData,
                context: modelContext,
                calendar: calendar
            )
            selectedBackupPreview = nil
            self.selectedBackupData = nil
            statusMessage = importStatusMessage(
                prefix: String(localized: "Replaced the current library."),
                result: result
            )
        } catch {
            handleBackupMutationError(error)
        }
    }

    private func deleteEverything() {
        do {
            let result = try BackupOperations.deleteEverything(context: modelContext)
            selectedBackupPreview = nil
            selectedBackupData = nil
            statusMessage = deleteStatusMessage(for: result)
        } catch {
            presentError(
                title: String(localized: "Library could not be cleared."),
                message: error.localizedDescription
            )
        }
    }

    private func handleBackupMutationError(_ error: any Error) {
        if let backupError = error as? BackupError,
           case .validationFailed(let preview) = backupError {
            selectedBackupPreview = preview
            presentError(
                title: String(localized: "Backup has validation issues."),
                message: String(localized: "Preview the validation issues before importing this backup.")
            )
        } else {
            presentError(
                title: String(localized: "Backup action failed."),
                message: error.localizedDescription
            )
        }
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
