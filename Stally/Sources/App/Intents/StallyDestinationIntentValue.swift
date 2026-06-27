//
//  StallyDestinationIntentValue.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

enum StallyDestinationIntentValue: String, AppEnum {
    case library
    case review
    case insights
    case archive
    case backupCenter
    case createItem
    case settings

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: .init("Destination", table: "AppIntents"))
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .library: .init(title: .init("Library", table: "AppIntents")),
            .review: .init(title: .init("Review", table: "AppIntents")),
            .insights: .init(title: .init("Insights", table: "AppIntents")),
            .archive: .init(title: .init("Archive", table: "AppIntents")),
            .backupCenter: .init(title: .init("Backup Center", table: "AppIntents")),
            .createItem: .init(title: .init("Create Item", table: "AppIntents")),
            .settings: .init(title: .init("Settings", table: "AppIntents"))
        ]
    }

    var linkDestination: StallyLinkDestination {
        switch self {
        case .library:
            .library
        case .review:
            .review
        case .insights:
            .insights
        case .archive:
            .archive
        case .backupCenter:
            .backupCenter
        case .createItem:
            .createItem
        case .settings:
            .settings
        }
    }
}
