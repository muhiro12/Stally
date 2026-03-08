import Foundation
import SwiftData

/// One daily choice mark for a single item.
@Model
public final class Mark {
    /// Stable mark identifier.
    @Attribute(.unique)
    public private(set) var id: UUID

    /// Storage-normalized day for the mark.
    public private(set) var day: Date

    /// Timestamp when the mark record was created.
    public private(set) var createdAt: Date

    /// Owning item for this mark.
    public private(set) var item: Item

    /// Creates a mark for an item on one day.
    public init(
        item: Item,
        day: Date,
        createdAt: Date = .now,
        id: UUID = .init()
    ) {
        self.id = id
        self.item = item
        self.day = day
        self.createdAt = createdAt
    }
}
