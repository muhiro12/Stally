//
//  ReviewActionRequest.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

/// One item and its current Review lane for applying the lane's primary action.
public struct ReviewActionRequest {
    /// Item whose lane action should be applied.
    public let item: Item
    /// Review lane that determines the action.
    public let lane: ReviewLane

    /// Creates one lane action request.
    public init(item: Item, lane: ReviewLane) {
        self.item = item
        self.lane = lane
    }
}
