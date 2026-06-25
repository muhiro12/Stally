//
//  ItemCategory.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation

enum ItemCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case clothing = "Clothing"
    case shoes = "Shoes"
    case bags = "Bags"
    case notebooks = "Notebooks"
    case other = "Other"

    var id: Self {
        self
    }

    var title: LocalizedStringResource {
        switch self {
        case .clothing:
            "Clothing"
        case .shoes:
            "Shoes"
        case .bags:
            "Bags"
        case .notebooks:
            "Notebooks"
        case .other:
            "Other"
        }
    }
}
