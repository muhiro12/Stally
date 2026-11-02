import Foundation
import MHFilePackage
import Synchronization

/// Maps Stally's manifest and image policy to bounded native package I/O.
enum TransferPackage {
    private static func transport() throws -> MHFilePackage {
        try .init(
            limits: .init(
                manifestBytes: TransferCodec.maximumJSONBytes,
                fileBytes: TransferCodec.maximumImageBytes,
                totalFileBytes: TransferCodec.maximumMediaBytes,
                fileCount: TransferCodec.maximumRecordCount
            ),
            manifestName: StallyDataContract.manifestFilename,
            assetDirectory: StallyDataContract.assetDirectory
        )
    }

    static func fileWrapper(manifest: Data, files: [String: Data]) throws -> FileWrapper {
        do {
            return try transport().fileWrapper(manifest: manifest, files: files)
        } catch let error as MHFilePackage.Failure {
            throw transferError(error)
        }
    }

    static func read(_ url: URL) async throws -> TransferArchive {
        let decoded = Mutex<TransferManifest?>(nil)
        do {
            let snapshot = try await transport().read(at: url) { bytes in
                let manifest = try TransferCodec.decode(bytes)
                decoded.withLock { $0 = manifest }
                return manifest.itemPhotos.compactMap { photo in
                    guard let path = photo.image.path else {
                        return nil
                    }
                    return .init(path: path, byteCount: photo.image.byteCount)
                }
            }
            guard let manifest = decoded.withLock({ $0 }) else { throw TransferError.invalidFile }
            for photo in manifest.itemPhotos {
                guard let path = photo.image.path else { continue }
                try Task.checkCancellation()
                guard let data = snapshot.files[path] else { throw TransferError.invalidFile }
                try TransferMedia.validate(data, image: photo.image)
            }
            return .init(manifest: manifest, media: snapshot.files)
        } catch let error as MHFilePackage.Failure {
            throw transferError(error)
        }
    }

    private static func transferError(_ error: MHFilePackage.Failure) -> TransferError {
        switch error {
        case .invalidPackage, .integrityMismatch:
            .invalidFile
        case .limitExceeded:
            .limitExceeded
        @unknown default:
            .invalidFile
        }
    }
}
