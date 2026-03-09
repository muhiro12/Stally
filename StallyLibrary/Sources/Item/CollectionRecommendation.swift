import Foundation

/// Suggested next actions derived from collection insight state.
public struct CollectionRecommendation: Equatable, Sendable {
    // swiftlint:disable raw_value_for_camel_cased_codable_enum
    public enum Kind: String, Codable, Equatable, Sendable {
        case startTracking
        case revisitQuietItems
        case addContext
        case protectStreak
    }
    // swiftlint:enable raw_value_for_camel_cased_codable_enum

    public let kind: Kind
    public let title: String
    public let message: String
    public let itemIDs: [UUID]

    public init(
        kind: Kind,
        title: String,
        message: String,
        itemIDs: [UUID]
    ) {
        self.kind = kind
        self.title = title
        self.message = message
        self.itemIDs = itemIDs
    }
}
