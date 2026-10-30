import CryptoKit
import Foundation
import ImageIO

/// Owned photo preparation; no source-library identifiers or permissions are retained.
public enum PhotoOperations {
    private static let cacheCostLimit = 33_554_432

    // NSCache requires object keys; only the digest is retained as a key.
    // swiftlint:disable:next legacy_objc_type
    @MainActor private static let previews: NSCache<NSData, CGImage> = {
        // swiftlint:disable:next legacy_objc_type
        let cache = NSCache<NSData, CGImage>()
        cache.totalCostLimit = cacheCostLimit
        return cache
    }()

    /// Consumes a provider file while its lifetime is valid, with a bounded read before decoding.
    @concurrent
    public static func prepare(fileURL: URL) async throws -> PreparedPhoto {
        let file = try FileHandle(forReadingFrom: fileURL)
        defer {
            try? file.close()
        }
        let data = try file.read(upToCount: PhotoProcessor.inputByteLimit + 1) ?? Data()
        return try PhotoProcessor.prepare(data)
    }

    /// Prepares delivered bytes without saving or changing an Item.
    @concurrent
    public static func prepare(data: Data) async throws -> PreparedPhoto {
        try PhotoProcessor.prepare(data)
    }

    /// Decodes a small SDR preview; the bounded cache is a disposable derivative.
    @preconcurrency
    @MainActor
    public static func preview(data: Data) -> CGImage? {
        // swiftlint:disable:next legacy_objc_type
        let key = Data(SHA256.hash(data: data)) as NSData
        if let image = previews.object(forKey: key) {
            return image
        }
        guard let image = try? PhotoProcessor.display(data, edge: PhotoProcessor.previewEdgeLimit) else {
            return nil
        }
        previews.setObject(image, forKey: key, cost: image.bytesPerRow * image.height)
        return image
    }

    /// Decodes the retained attachment for detail viewing without rewriting its bytes.
    @concurrent
    public static func image(data: Data) async throws -> CGImage {
        try Task.checkCancellation()
        return try PhotoProcessor.display(data, edge: PhotoProcessor.savedEdgeLimit)
    }
}
