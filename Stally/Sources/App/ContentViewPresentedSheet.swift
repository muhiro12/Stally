//
//  ContentViewPresentedSheet.swift
//  Stally
//
//  Created by Codex on 2026/07/22.
//

import Foundation

enum ContentViewPresentedSheet: Identifiable {
    case addItem
    case backupCenter
    case settings

    var id: String {
        switch self {
        case .addItem:
            "add-item"
        case .backupCenter:
            "backup-center"
        case .settings:
            "settings"
        }
    }
}
