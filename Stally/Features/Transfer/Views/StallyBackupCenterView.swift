import MHUI
import StallyLibrary
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct StallyBackupCenterView: View {
    private struct ImportPreview {
        let sourceURL: URL
        let analysis: StallyBackupImportAnalysis

        var sourceName: String {
            sourceURL.lastPathComponent
        }
    }

    private struct ImportExecutionSummary {
        let sourceName: String
        let result: StallyBackupImportResult
    }

    @Environment(\.mhTheme)
    private var theme

    @State private var exportDocument: StallyBackupDocument?
    @State private var isExporting = false
    @State private var exportFilename = exportFilename(for: .now)
    @State private var exportStatusMessage: String?
    @State private var isImporting = false
    @State private var importPreview: ImportPreview?
    @State private var importStatusMessage: String?
    @State private var importExecutionSummary: ImportExecutionSummary?

    let items: [Item]
    let onMergeImport: (StallyBackupSnapshot) throws -> StallyBackupImportResult

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            overviewCard
            exportSection
            importSection
            safetySection
        }
        .mhScreen(
            title: Text("Backup Center"),
            subtitle: Text("Prepare clean snapshots of your collection before you move them anywhere else.")
        )
        .navigationTitle("Backup Center")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument ?? .placeholder,
            contentType: .stallyBackup,
            defaultFilename: exportFilename
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: StallyBackupDocument.readableContentTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .alert(
            "Backup Export",
            isPresented: isExportStatusPresented
        ) {
            Button("OK", role: .cancel) {
                exportStatusMessage = nil
            }
        } message: {
            Text(exportStatusMessage ?? "")
        }
        .alert(
            "Backup Import",
            isPresented: isImportStatusPresented
        ) {
            Button("OK", role: .cancel) {
                importStatusMessage = nil
            }
        } message: {
            Text(importStatusMessage ?? "")
        }
    }
}

private extension StallyBackupCenterView {
    var isExportStatusPresented: Binding<Bool> {
        .init(
            get: {
                exportStatusMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    exportStatusMessage = nil
                }
            }
        )
    }

    var isImportStatusPresented: Binding<Bool> {
        .init(
            get: {
                importStatusMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    importStatusMessage = nil
                }
            }
        )
    }

    var activeSummary: ItemInsightsCalculator.ActiveCollectionSummary {
        ItemInsightsCalculator.activeSummary(from: items)
    }

    var archiveSummary: ItemInsightsCalculator.ArchiveCollectionSummary {
        ItemInsightsCalculator.archiveSummary(from: items)
    }

    var totalMarks: Int {
        activeSummary.totalMarks + archiveSummary.totalMarks
    }

    var latestChangeTitle: String {
        items
            .map(\.updatedAt)
            .max()?
            .formatted(date: .abbreviated, time: .omitted)
            ?? "None"
    }

    var overviewCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Backup Snapshot")
                .mhRowTitle()

            Text("Exports will capture your active items, archived items, and mark history in one portable package.")
                .mhRowSupporting()

            HStack(spacing: theme.spacing.group) {
                summaryMetric(
                    title: "Active",
                    value: "\(activeSummary.totalItems)"
                )
                summaryMetric(
                    title: "Archived",
                    value: "\(archiveSummary.totalItems)"
                )
                summaryMetric(
                    title: "Marks",
                    value: "\(totalMarks)"
                )
                summaryMetric(
                    title: "Latest Change",
                    value: latestChangeTitle
                )
            }
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var exportSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Export")
                .mhRowTitle()

            Text("Create a single backup file with every item, photo, note, and mark. Exports use the `.stallybackup` extension on top of JSON data.")
                .mhRowSupporting()

            Button("Export Backup", systemImage: "square.and.arrow.up") {
                startExport()
            }
            .buttonStyle(.mhSecondary)

            Text(exportDetailText)
                .mhRowSupporting()
        }
        .mhSection(title: Text("Export Tools"))
    }

    var importSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Import")
                .mhRowTitle()

            Text("Bring a backup back into Stally after previewing how many items would merge, replace, or be rejected.")
                .mhRowSupporting()

            Button("Choose Backup File", systemImage: "square.and.arrow.down") {
                isImporting = true
            }
            .buttonStyle(.mhSecondary)

            Text("Preview shows the snapshot contents, overlap with local items, and any warnings before import actions are enabled.")
                .mhRowSupporting()

            if let importExecutionSummary {
                importExecutionSummaryCard(importExecutionSummary)
            }

            if let importPreview {
                importPreviewCard(importPreview)
            }
        }
        .mhSection(title: Text("Import Tools"))
    }

    var safetySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Safety")
                .mhRowTitle()

            Text("Keep one recent export before you try any replace-style restore. Merge import will preserve local items; replace import will overwrite them.")
                .mhRowSupporting()

            Text("Backup files are meant for your own archive and transfer workflow, not for syncing between multiple devices at once.")
                .mhRowSupporting()
        }
        .mhSection(title: Text("Guidance"))
    }

    func summaryMetric(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .mhRowSupporting()
            Text(value)
                .mhRowValue(colorRole: .accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func importPreviewCard(
        _ preview: ImportPreview
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text(preview.sourceName)
                .mhRowTitle()

            Text(importPreviewSupportingText(preview))
                .mhRowSupporting()

            HStack(spacing: theme.spacing.group) {
                summaryMetric(
                    title: "Items",
                    value: "\(preview.analysis.summary.totalItems)"
                )
                summaryMetric(
                    title: "Archived",
                    value: "\(preview.analysis.summary.archivedItems)"
                )
                summaryMetric(
                    title: "Marks",
                    value: "\(preview.analysis.summary.totalMarks)"
                )
                summaryMetric(
                    title: "Existing",
                    value: "\(preview.analysis.summary.existingItems)"
                )
                summaryMetric(
                    title: "New",
                    value: "\(preview.analysis.summary.newItems)"
                )
            }

            if preview.analysis.issues.isEmpty {
                Text("No validation issues were found in this backup.")
                    .mhRowSupporting()
            } else {
                ForEach(preview.analysis.issues) { issue in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(issueLabel(issue))
                            .mhRowTitle()

                        Text(issue.message)
                            .mhRowSupporting()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                }
            }

            Button("Merge Into Library", systemImage: "square.stack.3d.up") {
                mergeImport(preview)
            }
            .buttonStyle(.mhSecondary)
            .disabled(!preview.analysis.canImport)

            Text("Merge import creates missing items, updates older local copies, and keeps newer local metadata when conflicts exist.")
                .mhRowSupporting()
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    private func importExecutionSummaryCard(
        _ summary: ImportExecutionSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Last Merge Result")
                .mhRowTitle()

            Text(summary.sourceName)
                .mhRowSupporting()

            HStack(spacing: theme.spacing.group) {
                summaryMetric(
                    title: "Created",
                    value: "\(summary.result.createdItems)"
                )
                summaryMetric(
                    title: "Updated",
                    value: "\(summary.result.updatedItems)"
                )
                summaryMetric(
                    title: "Marks Added",
                    value: "\(summary.result.insertedMarks)"
                )
                summaryMetric(
                    title: "Skipped",
                    value: "\(summary.result.skippedMarks)"
                )
            }
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    func startExport() {
        let snapshot = StallyBackupCodec.snapshot(
            from: items
        )
        exportDocument = StallyBackupDocument(
            snapshot: snapshot
        )
        exportFilename = Self.exportFilename(
            for: snapshot.exportedAt
        )
        isExporting = true
    }

    func handleExportResult(
        _ result: Result<URL, any Error>
    ) {
        switch result {
        case .success(let url):
            exportStatusMessage = "Backup saved as \(url.lastPathComponent)."
        case .failure(let error as CocoaError)
            where error.code == .userCancelled:
            exportStatusMessage = nil
        case .failure(let error):
            exportStatusMessage = (error as? LocalizedError)?.errorDescription
                ?? "Stally couldn't export this backup."
        }
    }

    func handleImportSelection(
        _ result: Result<[URL], any Error>
    ) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                importPreview = nil
                return
            }

            do {
                importPreview = try makeImportPreview(from: url)
            } catch {
                importPreview = nil
                importStatusMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Stally couldn't read this backup file."
            }
        case .failure(let error as CocoaError)
            where error.code == .userCancelled:
            importStatusMessage = nil
        case .failure(let error):
            importStatusMessage = (error as? LocalizedError)?.errorDescription
                ?? "Stally couldn't open the import picker."
        }
    }

    private func makeImportPreview(
        from url: URL
    ) throws -> ImportPreview {
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

    private func mergeImport(
        _ preview: ImportPreview
    ) {
        do {
            let result = try onMergeImport(
                preview.analysis.snapshot
            )
            importExecutionSummary = .init(
                sourceName: preview.sourceName,
                result: result
            )
            importPreview = nil
            importStatusMessage = "Merged \(preview.sourceName) into the current library."
        } catch {
            importStatusMessage = (error as? LocalizedError)?.errorDescription
                ?? "Stally couldn't merge this backup."
        }
    }

    var exportDetailText: String {
        "\(items.count) items and \(totalMarks) marks are ready to export right now."
    }

    private func importPreviewSupportingText(
        _ preview: ImportPreview
    ) -> String {
        "Exported \(preview.analysis.snapshot.exportedAt.formatted(date: .abbreviated, time: .shortened)) with schema v\(preview.analysis.snapshot.schemaVersion)."
    }

    func issueLabel(
        _ issue: StallyBackupImportIssue
    ) -> String {
        switch issue.severity {
        case .error:
            "Error: \(issue.code.rawValue)"
        case .warning:
            "Warning: \(issue.code.rawValue)"
        }
    }

    static func exportFilename(
        for date: Date
    ) -> String {
        "stally-backup-\(backupTimestampFormatter.string(from: date))"
    }

    static var backupTimestampFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyBackupCenterView(
            items: items,
            onMergeImport: { _ in
                .init(
                    analysis: .init(
                        snapshot: .init(
                            exportedAt: .now,
                            items: []
                        ),
                        summary: .init(
                            totalItems: 0,
                            archivedItems: 0,
                            totalMarks: 0,
                            existingItems: 0,
                            newItems: 0
                        ),
                        issues: []
                    ),
                    deletedItems: 0,
                    createdItems: 0,
                    updatedItems: 0,
                    insertedMarks: 0,
                    skippedMarks: 0
                )
            }
        )
    }
}
