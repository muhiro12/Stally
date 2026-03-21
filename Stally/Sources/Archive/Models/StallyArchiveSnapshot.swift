import Foundation
import StallyLibrary

struct StallyArchiveSnapshot {
    let archivedItems: [Item]
    let summary: ItemInsightsCalculator.ArchiveCollectionSummary

    var syncKey: String {
        let itemSignature = archivedItems.map { item in
            [
                item.id.uuidString,
                String(item.updatedAt.timeIntervalSinceReferenceDate),
                String(item.marks.count),
            ].joined(separator: "|")
        }.joined(separator: ",")

        return [
            itemSignature,
            String(summary.totalItems),
            String(summary.totalMarks),
        ].joined(separator: "#")
    }
}

enum StallyArchiveSnapshotBuilder {
    static func build(
        items: [Item]
    ) -> StallyArchiveSnapshot {
        let archivedItems = ItemInsightsCalculator
            .archivedItems(from: items)
            .sorted { left, right in
                left.updatedAt > right.updatedAt
            }

        return .init(
            archivedItems: archivedItems,
            summary: ItemInsightsCalculator.archiveSummary(
                from: archivedItems
            )
        )
    }
}
