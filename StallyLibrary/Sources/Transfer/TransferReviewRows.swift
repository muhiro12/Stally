import Foundation

/// Human review retains whole-record choices; photos without bytes inherit local media for comparison.
enum TransferReviewRows {
    static func rows(_ incoming: TransferManifest, local: TransferManifest) -> [TransferReview.Row] {
        itemRows(incoming, local: local) + markRows(incoming, local: local)
            + periodRows(incoming, local: local) + photoRows(incoming, local: local) + tagRows(incoming, local: local)
    }

    private static func itemRows(_ incoming: TransferManifest, local: TransferManifest) -> [TransferReview.Row] {
        let indexed = Dictionary(uniqueKeysWithValues: local.items.lazy.map { ($0.uuid, $0) })
        let tagsByName = Dictionary(grouping: incoming.tags + local.tags, by: \.name)
        let ambiguousNames = Set(
            tagsByName.filter { _, tags in
                Set(tags.map(\.uuid)).count > 1
            }.keys
        )
        var rows: [TransferReview.Row] = []
        for item in incoming.items {
            let current = indexed[item.uuid]
            rows.append(
                .init(
                    id: item.uuid,
                    kind: .item,
                    title: item.name,
                    isAddition: current == nil,
                    current: current.map { item in
                        TransferSummary.item(item, tags: local.tags, disambiguating: ambiguousNames)
                    },
                    proposed: TransferSummary.item(item, tags: incoming.tags, disambiguating: ambiguousNames),
                    isUnchanged: current == item,
                    affectedItemCount: 1
                )
            )
        }
        return rows
    }

    private static func markRows(_ incoming: TransferManifest, local: TransferManifest) -> [TransferReview.Row] {
        let indexed = Dictionary(uniqueKeysWithValues: local.itemMarks.lazy.map { ($0.uuid, $0) })
        let names = Dictionary(uniqueKeysWithValues: incoming.items.lazy.map { ($0.uuid, $0.name) })
        var rows: [TransferReview.Row] = []
        for mark in incoming.itemMarks {
            let current = indexed[mark.uuid]
            rows.append(
                .init(
                    id: mark.uuid,
                    kind: .mark,
                    title: names[mark.itemUUID] ?? mark.itemUUID.uuidString,
                    isAddition: current == nil,
                    current: current.map(TransferSummary.mark),
                    proposed: TransferSummary.mark(mark),
                    isUnchanged: current == mark,
                    affectedItemCount: 1
                )
            )
        }
        return rows
    }

    private static func periodRows(_ incoming: TransferManifest, local: TransferManifest) -> [TransferReview.Row] {
        let indexed = Dictionary(uniqueKeysWithValues: local.itemPeriods.lazy.map { ($0.uuid, $0) })
        let names = Dictionary(uniqueKeysWithValues: incoming.items.lazy.map { ($0.uuid, $0.name) })
        var rows: [TransferReview.Row] = []
        for period in incoming.itemPeriods {
            let current = indexed[period.uuid]
            rows.append(
                .init(
                    id: period.uuid,
                    kind: .period,
                    title: names[period.itemUUID] ?? period.itemUUID.uuidString,
                    isAddition: current == nil,
                    current: current.map(TransferSummary.period),
                    proposed: TransferSummary.period(period),
                    isUnchanged: current == period,
                    affectedItemCount: 1
                )
            )
        }
        return rows
    }

    private static func photoRows(_ incoming: TransferManifest, local: TransferManifest) -> [TransferReview.Row] {
        let indexed = Dictionary(uniqueKeysWithValues: local.itemPhotos.lazy.map { ($0.uuid, $0) })
        let names = Dictionary(uniqueKeysWithValues: incoming.items.lazy.map { ($0.uuid, $0.name) })
        var rows: [TransferReview.Row] = []
        for photo in incoming.itemPhotos {
            let current = indexed[photo.uuid]
            var effective = photo
            if photo.image.state != .included, let current { effective.image = current.image }
            rows.append(
                .init(
                    id: photo.uuid,
                    kind: .photo,
                    title: names[photo.itemUUID] ?? photo.itemUUID.uuidString,
                    isAddition: current == nil,
                    current: current.map(TransferSummary.photo),
                    proposed: TransferSummary.photo(photo),
                    isUnchanged: current == effective,
                    affectedItemCount: 1
                )
            )
        }
        return rows
    }

    private static func tagRows(_ incoming: TransferManifest, local: TransferManifest) -> [TransferReview.Row] {
        let indexed = Dictionary(uniqueKeysWithValues: local.tags.lazy.map { ($0.uuid, $0) })
        var usage: [UUID: Int] = [:]
        for item in local.items {
            for uuid in item.tagUUIDs { usage[uuid, default: 0] += 1 }
        }
        var rows: [TransferReview.Row] = []
        for tag in incoming.tags {
            let current = indexed[tag.uuid]
            rows.append(
                .init(
                    id: tag.uuid,
                    kind: .tag,
                    title: tag.name,
                    isAddition: current == nil,
                    current: current?.name,
                    proposed: tag.name,
                    isUnchanged: current == tag,
                    affectedItemCount: usage[tag.uuid, default: 0]
                )
            )
        }
        return rows
    }

    static func kinds(_ manifest: TransferManifest) -> [UUID: TransferReview.Kind] {
        var result: [UUID: TransferReview.Kind] = [:]
        manifest.items.forEach { result[$0.uuid] = .item }
        manifest.itemMarks.forEach { result[$0.uuid] = .mark }
        manifest.itemPeriods.forEach { result[$0.uuid] = .period }
        manifest.itemPhotos.forEach { result[$0.uuid] = .photo }
        manifest.tags.forEach { result[$0.uuid] = .tag }
        return result
    }

    static func parents(_ manifest: TransferManifest) -> [UUID: UUID] {
        var result: [UUID: UUID] = [:]
        manifest.itemMarks.forEach { result[$0.uuid] = $0.itemUUID }
        manifest.itemPeriods.forEach { result[$0.uuid] = $0.itemUUID }
        manifest.itemPhotos.forEach { result[$0.uuid] = $0.itemUUID }
        return result
    }
}
