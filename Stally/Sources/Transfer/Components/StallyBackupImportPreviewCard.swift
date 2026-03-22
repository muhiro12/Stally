import StallyLibrary
import SwiftUI

struct StallyBackupImportPreviewCard: View {
    private enum ActionID: String, Sendable {
        case merge
        case replace
    }

    @Namespace private var actionNamespace

    let preview: StallyBackupCenterState.ImportPreview
    let usesCompactLayout: Bool
    let onMerge: () -> Void
    let onReplace: () -> Void

    // swiftlint:disable closure_body_length
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Preview",
                title: preview.sourceName,
                subtitle: supportingText
            )

            StallyMetricGrid(
                metrics: metrics,
                usesCompactLayout: usesCompactLayout
            )

            if preview.analysis.issues.isEmpty {
                Text("No validation issues were found in this backup.")
                    .stallySupportingText()
            } else {
                ForEach(preview.analysis.issues) { issue in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(issueTitle(issue))
                            .stallyCardTitle()

                        Text(issue.message)
                            .stallySupportingText()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                }
            }

            GlassEffectContainer(
                spacing: StallyDesign.Layout.compactSpacing
            ) {
                VStack(
                    alignment: .leading,
                    spacing: StallyDesign.Layout.compactSpacing
                ) {
                    Button {
                        onMerge()
                    } label: {
                        Label(
                            "Merge Into Library",
                            systemImage: "square.stack.3d.up"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.glass)
                    .glassEffectID(
                        ActionID.merge,
                        in: actionNamespace
                    )
                    .disabled(!preview.analysis.canImport)

                    Button {
                        onReplace()
                    } label: {
                        Label(
                            "Replace Library",
                            systemImage: "arrow.trianglehead.2.clockwise.rotate.90"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.glass)
                    .glassEffectID(
                        ActionID.replace,
                        in: actionNamespace
                    )
                    .disabled(!preview.analysis.canImport)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(
                StallyLocalization.string(
                    "Merge import creates missing items, updates older local copies, and keeps newer "
                        + "local metadata when conflicts exist."
                )
            )
            .stallySupportingText()

            Text(
                StallyLocalization.string(
                    "Replace import deletes the current library first, then restores exactly what is in the backup."
                )
            )
            .stallySupportingText()
        }
        .stallyPanel(.elevated, padding: 16)
    }
    // swiftlint:enable closure_body_length
}

private extension StallyBackupImportPreviewCard {
    var metrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("Items"),
                value: "\(preview.analysis.summary.totalItems)"
            ),
            .init(
                title: StallyLocalization.string("Archived"),
                value: "\(preview.analysis.summary.archivedItems)"
            ),
            .init(
                title: StallyLocalization.string("Marks"),
                value: "\(preview.analysis.summary.totalMarks)"
            ),
            .init(
                title: StallyLocalization.string("Existing"),
                value: "\(preview.analysis.summary.existingItems)"
            ),
            .init(
                title: StallyLocalization.string("New"),
                value: "\(preview.analysis.summary.newItems)"
            )
        ]
    }

    var supportingText: String {
        StallyLocalization.format(
            "Exported %@ with schema v%lld.",
            preview.analysis.snapshot.exportedAt.formatted(
                date: .abbreviated,
                time: .shortened
            ),
            preview.analysis.snapshot.schemaVersion
        )
    }

    func issueTitle(
        _ issue: StallyBackupImportIssue
    ) -> String {
        let codeTitle: String
        switch issue.code {
        case .unsupportedSchemaVersion:
            codeTitle = StallyLocalization.string("Unsupported Schema Version")
        case .duplicateItemID:
            codeTitle = StallyLocalization.string("Duplicate Item ID")
        case .duplicateMarkID:
            codeTitle = StallyLocalization.string("Duplicate Mark ID")
        case .unknownCategory:
            codeTitle = StallyLocalization.string("Unknown Category")
        }

        return switch issue.severity {
        case .error:
            StallyLocalization.format(
                "Error: %@",
                codeTitle
            )
        case .warning:
            StallyLocalization.format(
                "Warning: %@",
                codeTitle
            )
        }
    }
}
