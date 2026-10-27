import Foundation
import SwiftData

/// One period of a relationship, retaining unknown and partial boundaries.
public typealias ItemPeriod = StallySchemaV3.ItemPeriod

// The Model macro needs explicit class visibility for its generated protocol witnesses.
// swiftlint:disable:next extension_access_modifier
extension StallySchemaV3 {
    /// One period of a relationship, retaining unknown and partial boundaries.
    @Model
    public final class ItemPeriod {
        /// Application-owned identity, retained across corrections and identity-preserving imports.
        public internal(set) var uuid = UUID()
        /// Unknown, year, month, or day precision in canonical Gregorian text.
        public internal(set) var startLocalDate: String?
        /// Unknown, year, month, or day precision; nil is required while ongoing.
        public internal(set) var endLocalDate: String?
        /// Distinguishes ongoing from an ended period with an unknown end date.
        public internal(set) var isOngoing: Bool = true
        /// Registration time, never an occurrence date or conflict ordering signal.
        public internal(set) var createdAt = Date()
        /// Owning Item, temporarily absent when a synchronized graph is incomplete.
        public internal(set) var item: Item?

        init(item: Item, startLocalDate: String?, endLocalDate: String?, isOngoing: Bool) {
            self.item = item
            self.startLocalDate = startLocalDate
            self.endLocalDate = endLocalDate
            self.isOngoing = isOngoing
        }
    }
}
