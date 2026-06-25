//
//  ItemMark.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation
import SwiftData

/// A single calendar-day record that an item was chosen.
@Model
public final class ItemMark {
    /// Stable mark identifier for backups and cross-surface references.
    @Attribute(.unique)
    public var uuid: UUID
    /// Start-of-day date for the marked calendar day.
    public var day: Date
    /// Date when this mark record was created.
    public var createdAt: Date
    /// The item this mark belongs to.
    public var item: Item?

    /// Creates a mark for a calendar day.
    public init(
        day: Date,
        createdAt: Date = .now,
        item: Item? = nil,
        uuid: UUID = .init()
    ) {
        self.uuid = uuid
        self.day = day
        self.createdAt = createdAt
        self.item = item
    }
}
