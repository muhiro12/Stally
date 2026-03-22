import StallyLibrary
import SwiftData
import SwiftUI
import TipKit
import UniformTypeIdentifiers

struct StallyBackupCenterView: View {
    @Environment(\.modelContext)
    var context
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    // swiftlint:disable:next private_swiftui_state
    @State var state = StallyBackupCenterState()

    let items: [Item]

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: StallyDesign.Layout.sectionSpacing
            ) {
                overviewCard
                exportSection
                importSection
                safetySection
                resetSection
            }
            .padding(.horizontal, StallyDesign.Layout.screenPadding)
            .padding(.top, 12)
            .safeAreaPadding(.bottom, 28)
        }
        .contentMargins(.bottom, 28, for: .scrollContent)
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
        .stallyScreenBackground()
    }
}

extension StallyBackupCenterView {
    var sectionSpacing: CGFloat {
        14
    }

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
        VStack(alignment: .leading, spacing: sectionSpacing) {
            StallySectionHeader(
                eyebrow: "Snapshot",
                title: "Current library at a glance",
                subtitle: "Exports will capture your active items, archived items, and mark history in one portable package."
            )

            StallyMetricGrid(
                metrics: overviewMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .stallyPanel(.accent)
    }

    var exportSection: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            StallySectionHeader(
                eyebrow: "Export",
                title: "Create a portable backup",
                subtitle:
                    """
                    Create a single backup file with every item, photo, note, and mark.
                    Exports use the `.stallybackup` extension on top of JSON data.
                    """
            )

            Button("Export Backup", systemImage: "square.and.arrow.up") {
                startExport()
            }
            .buttonStyle(StallySecondaryButtonStyle())
            .popoverTip(backupSafetyTip, arrowEdge: .top)

            Text(exportDetailText)
                .stallySupportingText()
        }
        .stallyPanel(.base)
    }

    var importSection: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            StallySectionHeader(
                eyebrow: "Import",
                title: "Preview before restoring",
                subtitle: "Bring a backup back into Stally after previewing how many items would merge, replace, or be rejected."
            )

            Button("Choose Backup File", systemImage: "square.and.arrow.down") {
                state.isImporting = true
            }
            .buttonStyle(StallySecondaryButtonStyle())

            Text(importSupportingText)
                .stallySupportingText()

            importPreviewArea
        }
        .stallyPanel(.base)
    }

    var safetySection: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            StallySectionHeader(
                eyebrow: "Guidance",
                title: "Handle restore flows carefully",
                subtitle: "Keep a recent export nearby before you try replace-style restore flows."
            )

            Text(
                """
                Keep one recent export before you try any replace-style restore.
                Merge import will preserve local items; replace import will overwrite them.
                """
            )
            .stallySupportingText()

            Text(
                """
                Backup files are meant for your own archive and transfer workflow,
                not for syncing between multiple devices at once.
                """
            )
            .stallySupportingText()
        }
        .stallyPanel(.quiet)
    }

    var resetSection: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            StallySectionHeader(
                eyebrow: "Reset",
                title: "Clear the current library deliberately",
                subtitle: "Use this only when you intentionally want an empty library before starting over or testing a restore flow."
            )

            Button("Delete Everything", systemImage: "trash") {
                state.isDeleteAllConfirmationPresented = true
            }
            .buttonStyle(StallySecondaryButtonStyle())
        }
        .stallyPanel(.base)
    }

    var backupSafetyTip: (any Tip)? {
        guard items.isEmpty == false else {
            return nil
        }

        return StallyTips.BackupSafetyTip()
    }
}
