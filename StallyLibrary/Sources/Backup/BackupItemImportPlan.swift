//
//  BackupItemImportPlan.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/12.
//

struct BackupItemImportPlan {
    let backupItem: BackupItem
    let existingItem: Item?
    let marks: [BackupMark]
}
