import Foundation

/// The exact assignment snapshot reviewed before replacing one Tag with another.
public struct TagConsolidation: Sendable {
    public let sourceID: UUID
    public let survivorID: UUID
    public let sourceName: String
    public let survivorName: String
    public let affectedItemIDs: Set<UUID>
    let survivorItemIDs: Set<UUID>
}
