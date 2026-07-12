//
//  ItemCategory.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation

public enum ItemCategory: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case clothing = "Clothing"
    case shoes = "Shoes"
    case bags = "Bags"
    case notebooks = "Notebooks"
    case other = "Other"

    public var id: Self {
        self
    }

    public var title: LocalizedStringResource {
        switch self {
        case .clothing:
            .init("Clothing", bundle: #bundle)
        case .shoes:
            .init("Shoes", bundle: #bundle)
        case .bags:
            .init("Bags", bundle: #bundle)
        case .notebooks:
            .init("Notebooks", bundle: #bundle)
        case .other:
            .init("Other", bundle: #bundle)
        }
    }
}
