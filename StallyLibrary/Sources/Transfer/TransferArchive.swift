import Foundation

/// An immutable, bounded snapshot retained through review, independent of a file provider.
public struct TransferArchive: Sendable {
    let manifest: TransferManifest
    let media: [String: Data]

    /// Builds the native directory package from already validated, saved bytes.
    public func fileWrapper() throws -> FileWrapper {
        let records = try TransferCodec.encode(manifest)
        var children = ["records.json": FileWrapper(regularFileWithContents: records)]
        if !media.isEmpty {
            children["media"] = FileWrapper(
                directoryWithFileWrappers: media.mapValues { data in
                    FileWrapper(regularFileWithContents: data)
                }
            )
        }
        return FileWrapper(directoryWithFileWrappers: children)
    }
}
