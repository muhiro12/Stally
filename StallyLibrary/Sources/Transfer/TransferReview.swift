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
        public let current: String?
        public let proposed: String
        public let isUnchanged: Bool
        public let affectedItemCount: Int
    }

    public let id = UUID()
    public let rows: [Row]
    let incoming: TransferArchive
    let baseline: TransferArchive

    /// Additions are selected initially; differences always keep the current record by default.
    public var defaultSelection: Set<UUID> {
        Set(rows.filter { $0.current == nil }.map(\.id))
    }
    /// Supplies the actual image being reviewed; an omitted incoming image returns nil.
    public func imageData(for uuid: UUID, fromFile: Bool) -> Data? {
        let archive = fromFile ? incoming : baseline
        guard let path = archive.manifest.itemPhotos.first(where: { $0.uuid == uuid })?.image.path else {
            return nil
        }
        return archive.media[String(path.dropFirst("media/".count))]
    }
}
