import Foundation

/// Serializable mark payload stored inside a backup item.
public struct StallyBackupMark: Codable, Equatable, Identifiable, Sendable {
    /// Stable mark identifier.
    public let id: UUID

    /// Storage-normalized day represented by the mark.
    public let day: Date

    /// Timestamp when the mark was first created.
    public let createdAt: Date

    /// Creates a backup mark payload.
    public init(
        id: UUID,
        day: Date,
        createdAt: Date
    ) {
        self.id = id
        self.day = day
        self.createdAt = createdAt
    }
}

extension StallyBackupMark {
    static func sortForBackup(
        _ lhs: StallyBackupMark,
        _ rhs: StallyBackupMark
    ) -> Bool {
        if lhs.day != rhs.day {
            return lhs.day < rhs.day
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }
}
