import Foundation

/// The deliberately small, captured projection used by system search.
public struct ItemSearchIndexEntry: Codable, Hashable, Sendable {
    /// Stable domain identity, never derived from the displayed name.
    public let uuid: UUID
    /// Captured user-facing Item name.
    public let name: String
    /// Captured category used to derive localized search metadata.
    public let categoryRawValue: String
    /// Placement retained for searching Archive without changing its status.
    public let isArchived: Bool

    /// Captures the approved searchable fields without private context or history.
    public init(uuid: UUID, name: String, categoryRawValue: String, isArchived: Bool) {
        self.uuid = uuid
        self.name = name
        self.categoryRawValue = categoryRawValue
        self.isArchived = isArchived
    }
}
