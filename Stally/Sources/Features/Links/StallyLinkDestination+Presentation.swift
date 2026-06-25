//
//  StallyLinkDestination+Presentation.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

extension StallyLinkDestination {
    var systemImageName: String {
        switch self {
        case .library:
            "tray"
        case .archive:
            "archivebox"
        case .review:
            "text.badge.checkmark"
        case .insights:
            "chart.line.uptrend.xyaxis"
        case .backupCenter:
            "externaldrive"
        case .createItem:
            "plus"
        case .settings:
            "gear"
        }
    }
}
