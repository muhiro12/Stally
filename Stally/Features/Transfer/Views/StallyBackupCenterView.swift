import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyBackupCenterView: View {
    @Environment(\.mhTheme)
    private var theme

    let items: [Item]

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
    }
}

private extension StallyBackupCenterView {
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

            Text("Create a single backup file with every item, photo, note, and mark. The file export action lands next.")
                .mhRowSupporting()

            Button("Export Backup", systemImage: "square.and.arrow.up") {
                // Implemented in a follow-up commit.
            }
            .buttonStyle(.mhSecondary)
            .disabled(true)
        }
        .mhSection(title: Text("Export Tools"))
    }

    var importSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Import")
                .mhRowTitle()

            Text("Bring a backup back into Stally after previewing how many items would merge, replace, or be rejected.")
                .mhRowSupporting()

            Button("Import Backup", systemImage: "square.and.arrow.down") {
                // Implemented in a follow-up commit.
            }
            .buttonStyle(.mhSecondary)
            .disabled(true)
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
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyBackupCenterView(items: items)
    }
}
