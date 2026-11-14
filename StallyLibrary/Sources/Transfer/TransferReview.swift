import Foundation

/// A review binds immutable file contents to the library snapshot that was inspected.
public struct TransferReview: Sendable, Identifiable {
    public enum Kind: String, Sendable {
        case item
        case mark
        case period
        case photo
        case tag
    }

    public struct Row: Sendable, Identifiable {
        public let id: UUID
        public let kind: Kind
        public let title: String
        public var current: String? { currentSummary() }
        public var proposed: String { proposedSummary() }
        public let isAddition: Bool
        private let currentSummary: @Sendable () -> String?
        private let proposedSummary: @Sendable () -> String
        public let isUnchanged: Bool
        public let affectedItemCount: Int

        init(
            id: UUID,
            kind: Kind,
            title: String,
            isAddition: Bool,
            current: @autoclosure @escaping @Sendable () -> String?,
            proposed: @autoclosure @escaping @Sendable () -> String,
            isUnchanged: Bool,
            affectedItemCount: Int
        ) {
            self.id = id
            self.kind = kind
            self.title = title
            self.isAddition = isAddition
            currentSummary = current
            proposedSummary = proposed
            self.isUnchanged = isUnchanged
            self.affectedItemCount = affectedItemCount
        }
    }

    public let id = UUID()
    public let rows: [Row]
    let incoming: TransferArchive
    let baseline: TransferArchive

    /// Additions are selected initially; differences always keep the current record by default.
    public var defaultSelection: Set<UUID> {
        Set(rows.lazy.filter(\.isAddition).map(\.id))
    }
    /// Supplies the actual image being reviewed; an omitted incoming image returns nil.
    public func imageData(for uuid: UUID, fromFile: Bool) -> Data? {
        let archive = fromFile ? incoming : baseline
        guard let path = archive.manifest.itemPhotos.first(where: { $0.uuid == uuid })?.image.path else {
            return nil
        }
        return try? archive.imageData(path: path)
    }
}
