import Foundation

/// Supported Stally item categories.
public enum ItemCategory: String, CaseIterable, Codable, Sendable {
    case clothing
    case shoes
    case bags
    case notebooks
    case other

    /// Calm display title used by the app UI.
    public var title: String {
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

    /// SF Symbol paired with the category in Stally surfaces.
    public var symbolName: String {
        switch self {
        case .clothing:
            "hanger"
        case .shoes:
            "shoe.2.fill"
        case .bags:
            "bag.fill"
        case .notebooks:
            "book.closed.fill"
        case .other:
            "square.grid.2x2.fill"
        }
    }
}
