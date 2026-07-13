//
//  ReviewLane.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Product review lanes that gather items needing gentle attention.
public enum ReviewLane: CaseIterable, Hashable, Identifiable, Sendable {
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
            .init("Dormant", bundle: #bundle)
        case .needsFirstMark:
            .init("Needs First Mark", bundle: #bundle)
        case .recoveryCandidates:
            .init("Recovery Candidates", bundle: #bundle)
        }
    }

    /// Quiet explanation of the lane meaning.
    public var summary: LocalizedStringResource {
        switch self {
        case .dormant:
            .init(
                "Items whose last mark feels far enough away to revisit.",
                bundle: #bundle
            )
        case .needsFirstMark:
            .init(
                "Items that have been waiting quietly without a first mark.",
                bundle: #bundle
            )
        case .recoveryCandidates:
            .init(
                "Archived items whose history suggests they may deserve another turn.",
                bundle: #bundle
            )
        }
    }

    /// Empty-state copy for a clear lane.
    public var emptyMessage: LocalizedStringResource {
        switch self {
        case .dormant:
            .init("Nothing currently looks dormant.", bundle: #bundle)
        case .needsFirstMark:
            .init("Nothing in this lane right now.", bundle: #bundle)
        case .recoveryCandidates:
            .init("Nothing is asking to come back right now.", bundle: #bundle)
        }
    }
}
