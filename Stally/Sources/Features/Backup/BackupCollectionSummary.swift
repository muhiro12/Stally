//
//  BackupCollectionSummary.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

struct BackupCollectionSummary: Equatable {
    let itemCount: Int
    let archivedItemCount: Int
    let markCount: Int

    init(items: [Item]) {
        itemCount = items.count
        archivedItemCount = items.filter(\.isArchived).count
        markCount = items.reduce(0) { count, item in
            count + item.marks.count
        }
    }
}
