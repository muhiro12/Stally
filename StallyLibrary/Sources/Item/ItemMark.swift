import Foundation
import SwiftData

/// One occurrence, retaining civil-day or minute precision without a time zone.
public typealias ItemMark = StallySchema.ItemMark

// The Model macro needs explicit class visibility for its generated protocol witnesses.
// swiftlint:disable:next extension_access_modifier
extension StallySchema {
    /// One occurrence, retaining civil-day or minute precision without a time zone.
    @Model
    public final class ItemMark {
        /// Application-owned identity, retained across corrections and identity-preserving imports.
        public internal(set) var uuid = UUID()
        /// Canonical Gregorian day or minute knowledge without a time zone.
        public internal(set) var localDateTime: String = ""
        /// Registration time, never an occurrence date or conflict ordering signal.
        public internal(set) var createdAt = Date()
        /// Owning Item, temporarily absent when a synchronized graph is incomplete.
        public internal(set) var item: Item?

        init(item: Item, localDateTime: String) {
            self.item = item
            self.localDateTime = localDateTime
        }
    }
}
