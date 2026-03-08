import MHUI
import StallyLibrary
import SwiftUI

struct StallyBackupImportExecutionSummaryCard: View {
    @Environment(\.mhTheme)
    private var theme

    let summary: StallyBackupCenterState.ImportExecutionSummary
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text(summary.title)
                .mhRowTitle()

            Text(summary.sourceName)
                .mhRowSupporting()

            StallyMetricGrid(
                metrics: metrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }
}

private extension StallyBackupImportExecutionSummaryCard {
    var metrics: [StallyMetricGrid.Metric] {
        [
            .init(title: "Deleted", value: "\(summary.result.deletedItems)"),
            .init(title: "Created", value: "\(summary.result.createdItems)"),
            .init(title: "Updated", value: "\(summary.result.updatedItems)"),
            .init(
                title: "Marks Added",
                value: "\(summary.result.insertedMarks)"
            ),
            .init(title: "Skipped", value: "\(summary.result.skippedMarks)")
        ]
    }
}
