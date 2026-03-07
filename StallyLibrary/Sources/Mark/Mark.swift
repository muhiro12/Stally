import Foundation
import SwiftData

/// One daily choice mark for a single item.
@Model
public final class Mark {
    @Attribute(.unique)
    public private(set) var id: UUID
    public private(set) var day: Date
    public private(set) var createdAt: Date
    public private(set) var item: Item

    public init(
        id: UUID = .init(),
        item: Item,
        day: Date,
        createdAt: Date = .now
    ) {
        self.id = id
        self.item = item
        self.day = day
        self.createdAt = createdAt
    }
}
