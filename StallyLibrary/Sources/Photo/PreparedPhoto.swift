import Foundation

/// A validated owned attachment and its independently rebuildable preview.
public struct PreparedPhoto: Sendable {
    public let imageData: Data
    public let thumbnailData: Data?
}
