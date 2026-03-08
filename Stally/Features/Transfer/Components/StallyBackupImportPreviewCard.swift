import MHUI
import StallyLibrary
import SwiftUI

struct StallyBackupImportPreviewCard: View {
    @Environment(\.mhTheme)
    private var theme

    let preview: StallyBackupCenterState.ImportPreview
    let usesCompactLayout: Bool
    let onMerge: () -> Void
    let onReplace: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text(preview.sourceName)
                .mhRowTitle()

            Text(supportingText)
                .mhRowSupporting()

            StallyMetricGrid(
                metrics: metrics,
                usesCompactLayout: usesCompactLayout
            )

            if preview.analysis.issues.isEmpty {
                Text("No validation issues were found in this backup.")
                    .mhRowSupporting()
            } else {
                ForEach(preview.analysis.issues) { issue in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(issueTitle(issue))
                            .mhRowTitle()

                        Text(issue.message)
                            .mhRowSupporting()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                }
            }

            Button("Merge Into Library", systemImage: "square.stack.3d.up") {
                onMerge()
            }
            .buttonStyle(.mhSecondary)
            .disabled(!preview.analysis.canImport)

            Button("Replace Library", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") {
                onReplace()
            }
            .buttonStyle(.mhSecondary)
            .disabled(!preview.analysis.canImport)

            Text("Merge import creates missing items, updates older local copies, and keeps newer local metadata when conflicts exist.")
                .mhRowSupporting()

            Text("Replace import deletes the current library first, then restores exactly what is in the backup.")
                .mhRowSupporting()
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }
}

private extension StallyBackupImportPreviewCard {
    var metrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: "Items",
                value: "\(preview.analysis.summary.totalItems)"
            ),
            .init(
                title: "Archived",
                value: "\(preview.analysis.summary.archivedItems)"
            ),
            .init(
                title: "Marks",
                value: "\(preview.analysis.summary.totalMarks)"
            ),
            .init(
                title: "Existing",
                value: "\(preview.analysis.summary.existingItems)"
            ),
            .init(
                title: "New",
                value: "\(preview.analysis.summary.newItems)"
            )
        ]
    }

    var supportingText: String {
        "Exported \(preview.analysis.snapshot.exportedAt.formatted(date: .abbreviated, time: .shortened)) with schema v\(preview.analysis.snapshot.schemaVersion)."
    }

    func issueTitle(
        _ issue: StallyBackupImportIssue
    ) -> String {
        switch issue.severity {
        case .error:
            "Error: \(issue.code.rawValue)"
        case .warning:
            "Warning: \(issue.code.rawValue)"
        }
    }
}
