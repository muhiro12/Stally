//
//  StallyPreviewItemSeed.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

#if DEBUG
struct StallyPreviewItemSeed {
    let name: String
    let category: ItemCategory
    let note: String
    let createdDaysAgo: Int
    let markedDaysAgo: [Int]
    let archivedDaysAgo: Int?
}
#endif
