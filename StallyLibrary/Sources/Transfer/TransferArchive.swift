import Foundation

/// An immutable, bounded snapshot retained through review, independent of a file provider.
public struct TransferArchive: Sendable {
    let manifest: TransferManifest
    let media: [String: Data]

    /// Builds the native directory package from already validated, saved bytes.
    public func fileWrapper() throws -> FileWrapper {
        try TransferPackage.fileWrapper(manifest: TransferCodec.encode(manifest), files: media)
    }
}
