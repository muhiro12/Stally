import StallyLibrary
import SwiftData
import SwiftUI

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyBackupCenterView(
            items: items,
            onMergeImport: { _ in
                previewImportResult()
            },
            onReplaceImport: { _ in
                previewImportResult()
            },
            onDeleteAll: {
                // no-op
            }
        )
    }
}

private func previewImportResult() -> StallyBackupImportResult {
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
