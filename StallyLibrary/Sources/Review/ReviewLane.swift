//
//  ReviewLane.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Product review lanes that gather items needing gentle attention.
public enum ReviewLane: CaseIterable, Identifiable, Sendable {
    case needsFirstMark
    case dormant
    case recoveryCandidates

    /// Stable lane identity.
    public var id: Self {
        self
    }

    /// User-facing lane title.
    public var title: LocalizedStringResource {
        switch self {
        case .dormant:
            "Dormant"
        case .needsFirstMark:
            "Needs First Mark"
        case .recoveryCandidates:
            "Recovery Candidates"
        }
    }

    /// Quiet explanation of the lane meaning.
    public var summary: LocalizedStringResource {
        switch self {
        case .dormant:
            "Items whose last mark feels far enough away to revisit."
        case .needsFirstMark:
            "Items that have been waiting quietly without a first mark."
        case .recoveryCandidates:
            "Archived items whose history suggests they may deserve another turn."
        }
    }

    /// Empty-state copy for a clear lane.
    public var emptyMessage: LocalizedStringResource {
        switch self {
        case .dormant:
            "Nothing currently looks dormant."
        case .needsFirstMark:
            "Nothing in this lane right now."
        case .recoveryCandidates:
            "Nothing is asking to come back right now."
        }
    }
}
