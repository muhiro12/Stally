//
//  ReviewSnapshot.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Current Review lane membership for a collection of items.
public struct ReviewSnapshot {
    /// Active items waiting for their first mark.
    public let needsFirstMark: [Item]
    /// Previously marked active items that have gone quiet.
    public let dormant: [Item]
    /// Archived items whose history suggests they may deserve another turn.
    public let recoveryCandidates: [Item]

    /// Whether all Review lanes are currently clear.
    public var isEmpty: Bool {
        needsFirstMark.isEmpty && dormant.isEmpty && recoveryCandidates.isEmpty
    }

    /// Returns items for one Review lane.
    public func items(in lane: ReviewLane) -> [Item] {
        switch lane {
        case .dormant:
            dormant
        case .needsFirstMark:
            needsFirstMark
        case .recoveryCandidates:
            recoveryCandidates
        }
    }
}
