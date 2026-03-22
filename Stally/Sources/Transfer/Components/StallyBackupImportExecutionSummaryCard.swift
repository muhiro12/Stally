import StallyLibrary
import SwiftUI

struct StallyBackupImportExecutionSummaryCard: View {
    let summary: StallyBackupCenterState.ImportExecutionSummary
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Imported",
                title: summary.title,
                subtitle: summary.sourceName
            )

            StallyMetricGrid(
                metrics: metrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .stallyPanel(.elevated, padding: 16)
    }
}

private extension StallyBackupImportExecutionSummaryCard {
    var metrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Deleted"),
                value: "\(summary.result.deletedItems)"
            ),
            .init(
                title: StallyLocalization.string("Created"),
                value: "\(summary.result.createdItems)"
            ),
            .init(
                title: StallyLocalization.string("Updated"),
                value: "\(summary.result.updatedItems)"
            ),
            .init(
                title: StallyLocalization.string("Marks Added"),
                value: "\(summary.result.insertedMarks)"
            ),
            .init(
                title: StallyLocalization.string("Skipped"),
                value: "\(summary.result.skippedMarks)"
            )
        ]
    }
}
