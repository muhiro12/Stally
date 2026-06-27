//
//  StallyItemCategoryIntentValue.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents

enum StallyItemCategoryIntentValue: String, AppEnum {
    case clothing
    case shoes
    case bags
    case notebooks
    case other

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: .init("Category", table: "AppIntents"))
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .clothing: .init(title: .init("Clothing", table: "AppIntents")),
            .shoes: .init(title: .init("Shoes", table: "AppIntents")),
            .bags: .init(title: .init("Bags", table: "AppIntents")),
            .notebooks: .init(title: .init("Notebooks", table: "AppIntents")),
            .other: .init(title: .init("Other", table: "AppIntents"))
        ]
    }

    var itemCategory: ItemCategory {
        switch self {
        case .clothing:
            .clothing
        case .shoes:
            .shoes
        case .bags:
            .bags
        case .notebooks:
            .notebooks
        case .other:
            .other
        }
    }
}
