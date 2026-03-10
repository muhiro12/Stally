import MHUI
import StallyLibrary
import SwiftData
import SwiftUI
import TipKit
import UniformTypeIdentifiers

struct StallyBackupCenterView: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    // swiftlint:disable:next private_swiftui_state
    @State var state = StallyBackupCenterState()

    let items: [Item]
    let onMergeImport: (StallyBackupSnapshot) throws -> StallyBackupImportResult
    let onReplaceImport: (StallyBackupSnapshot) throws -> StallyBackupImportResult
    let onDeleteAll: () throws -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.group) {
            overviewCard
            exportSection
            importSection
            safetySection
            resetSection
        }
        .mhScreen(
            title: Text("Backup Center"),
            subtitle: Text("Prepare clean snapshots of your collection before you move them anywhere else.")
        )
        .navigationTitle("Backup Center")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $state.isExporting,
            document: state.exportDocument ?? .placeholder,
            contentType: .stallyBackup,
            defaultFilename: state.exportFilename
        ) { result in
            state.recordExportResult(result)
        }
        .fileImporter(
            isPresented: $state.isImporting,
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
                state.exportStatusMessage = nil
            }
        } message: {
            Text(state.exportStatusMessage ?? "")
        }
        .alert(
            "Backup Import",
            isPresented: isImportStatusPresented
        ) {
            Button("OK", role: .cancel) {
                state.importStatusMessage = nil
            }
        } message: {
            Text(state.importStatusMessage ?? "")
        }
        .confirmationDialog(
            "Replace the Current Library",
            isPresented: $state.isReplaceConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Replace Library", role: .destructive) {
                guard let preview = state.importPreview else {
                    return
                }

                replaceImport(preview)
            }
            Button("Cancel", role: .cancel) {
                // no-op
            }
        } message: {
            Text("This removes the current library before restoring the selected backup.")
        }
        .confirmationDialog(
            "Delete Every Item",
            isPresented: $state.isDeleteAllConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllItems()
            }
            Button("Cancel", role: .cancel) {
                // no-op
            }
        } message: {
            Text("This clears Home, Archive, photos, notes, and mark history from the current library.")
        }
    }
}

extension StallyBackupCenterView {
    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var isExportStatusPresented: Binding<Bool> {
        .init(
            get: {
                state.exportStatusMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    state.exportStatusMessage = nil
                }
            }
        )
    }

    var isImportStatusPresented: Binding<Bool> {
        .init(
            get: {
                state.importStatusMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    state.importStatusMessage = nil
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

    var overviewMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Active"),
                value: "\(activeSummary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("Archived"),
                value: "\(archiveSummary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("Marks"),
                value: "\(totalMarks)"
            ),
            .init(
                title: StallyLocalization.string("Latest Change"),
                value: latestChangeTitle
            )
        ]
    }

    var latestChangeTitle: String {
        items
            .map(\.updatedAt)
            .max()?
            .formatted(date: .abbreviated, time: .omitted)
            ?? StallyLocalization.string("None")
    }

    var exportDetailText: String {
        StallyLocalization.format(
            "%1$lld items and %2$lld marks are ready to export right now.",
            items.count,
            totalMarks
        )
    }

    var overviewCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Backup Snapshot")
                .mhRowTitle()

            Text("Exports will capture your active items, archived items, and mark history in one portable package.")
                .mhRowSupporting()

            StallyMetricGrid(
                metrics: overviewMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    var exportSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Export")
                .mhRowTitle()

            Text(
                """
                Create a single backup file with every item, photo, note, and mark.
                Exports use the `.stallybackup` extension on top of JSON data.
                """
            )
            .mhRowSupporting()

            Button("Export Backup", systemImage: "square.and.arrow.up") {
                startExport()
            }
            .buttonStyle(.mhSecondary)
            .popoverTip(backupSafetyTip, arrowEdge: .top)

            Text(exportDetailText)
                .mhRowSupporting()
        }
        .mhSection(title: Text("Export Tools"))
    }

    var importSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Import")
                .mhRowTitle()

            Text(
                "Bring a backup back into Stally after previewing how many items would merge, replace, or be rejected."
            )
            .mhRowSupporting()

            Button("Choose Backup File", systemImage: "square.and.arrow.down") {
                state.isImporting = true
            }
            .buttonStyle(.mhSecondary)

            Text(importSupportingText)
                .mhRowSupporting()

            importPreviewArea
        }
        .mhSection(title: Text("Import Tools"))
    }

    var safetySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Safety")
                .mhRowTitle()

            Text(
                """
                Keep one recent export before you try any replace-style restore.
                Merge import will preserve local items; replace import will overwrite them.
                """
            )
            .mhRowSupporting()

            Text(
                """
                Backup files are meant for your own archive and transfer workflow,
                not for syncing between multiple devices at once.
                """
            )
            .mhRowSupporting()
        }
        .mhSection(title: Text("Guidance"))
    }

    var resetSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Reset")
                .mhRowTitle()

            Text(
                """
                Use this only when you intentionally want an empty library
                before starting over or testing a restore flow.
                """
            )
            .mhRowSupporting()

            Button("Delete Everything", systemImage: "trash") {
                state.isDeleteAllConfirmationPresented = true
            }
            .buttonStyle(.mhSecondary)
        }
        .mhSection(title: Text("Reset Tools"))
    }

    var backupSafetyTip: (any Tip)? {
        guard items.isEmpty == false else {
            return nil
        }

        return StallyTips.BackupSafetyTip()
    }
}
