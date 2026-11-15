import Foundation

/// Immutable record values and operation-owned media, independent of the original provider.
public struct TransferArchive: Sendable {
    private enum Storage: Sendable {
        case memory([String: Data])
        case staged(TransferStaging)
    }

    let manifest: TransferManifest
    private let storage: Storage

    init(manifest: TransferManifest, media: [String: Data]) {
        self.manifest = manifest
        storage = .memory(media)
    }

    init(manifest: TransferManifest, staging: TransferStaging) {
        self.manifest = manifest
        storage = .staged(staging)
    }

    func imageData(path: String) throws -> Data {
        switch storage {
        case .memory(let media):
            guard let data = media[path] else { throw TransferError.invalidFile }
            return data
        case .staged(let staging):
            return try staging.data(path: path)
        }
    }

    /// Compatibility adapter; normal app and Intent exports use the URL writer.
    public func fileWrapper() throws -> FileWrapper {
        let root = FileWrapper(directoryWithFileWrappers: [
            "manifest.json": FileWrapper(regularFileWithContents: try TransferCodec.encode(manifest))
        ])
        var assets: [String: FileWrapper] = [:]
        for photo in manifest.itemPhotos {
            if let path = photo.image.path {
                assets[URL(filePath: path).lastPathComponent] = .init(
                    regularFileWithContents: try imageData(path: path)
                )
            }
        }
        let directory = FileWrapper(directoryWithFileWrappers: assets)
        directory.preferredFilename = "assets"
        root.addFileWrapper(directory)
        return root
    }
}
