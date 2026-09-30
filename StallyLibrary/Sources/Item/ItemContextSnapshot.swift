import Foundation

/// Value-only context for an Item's secondary actions, never a mutation permit.
public struct ItemContextSnapshot: Equatable, Sendable {
    /// Canonical identity to resolve again when an action executes.
    public let itemID: UUID
    /// Captured presentation name; it is not an identity key.
    public let name: String
    /// Current guards for history and collection placement.
    public let capabilities: ItemCapabilities
    /// Whether the captured local day already has a Mark.
    public let isMarkedToday: Bool
    /// A localized report only when start knowledge is valid.
    public let timeReport: String?
}
