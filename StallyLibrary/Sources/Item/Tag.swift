import Foundation
import SwiftData

/// A shared identity; equal names do not imply equal Tags.
public typealias Tag = StallySchemaV3.Tag

// The Model macro needs explicit class visibility for its generated protocol witnesses.
// swiftlint:disable:next extension_access_modifier
extension StallySchemaV3 {
    /// A shared identity; equal names do not imply equal Tags.
    @Model
    public final class Tag {
        /// Application-owned identity, retained across corrections and identity-preserving imports.
        public internal(set) var uuid = UUID()
        /// The exact user-confirmed name; equality does not establish identity.
        public internal(set) var name: String = ""
        /// Assigned Items; deleting this Tag never deletes them.
        @Relationship(deleteRule: .nullify)
        public internal(set) var items: [Item]? = []  // swiftlint:disable:this discouraged_optional_collection

        init(name: String) {
            self.name = name
        }
    }
}
