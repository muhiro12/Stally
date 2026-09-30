import Foundation

/// Captured Review membership for system consumers that must not retain live models.
public struct ReviewIdentifiersSnapshot: Equatable, Sendable {
    /// Active Items waiting for a first Mark.
    public let needsFirstMark: [UUID]
    /// Previously marked active Items that have gone quiet.
    public let dormant: [UUID]
    /// Archived Items that may deserve another turn.
    public let recoveryCandidates: [UUID]

    init(snapshot: ReviewSnapshot) {
        needsFirstMark = snapshot.needsFirstMark.map(\.uuid)
        dormant = snapshot.dormant.map(\.uuid)
        recoveryCandidates = snapshot.recoveryCandidates.map(\.uuid)
    }

    /// Returns stable identities for one captured lane.
    public func itemIDs(in lane: ReviewLane) -> [UUID] {
        switch lane {
        case .needsFirstMark:
            needsFirstMark
        case .dormant:
            dormant
        case .recoveryCandidates:
            recoveryCandidates
        }
    }
}
