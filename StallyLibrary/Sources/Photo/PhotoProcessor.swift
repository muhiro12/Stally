import Foundation
import ImageIO
import UniformTypeIdentifiers

/// One native image pipeline for picker ingestion and saved-image validation.
enum PhotoProcessor {
    static let inputByteLimit = 67_108_864
    static let savedByteLimit = 8_388_608
    static let previewByteLimit = 2_097_152
    static let inputEdgeLimit = 16_384
    static let inputPixelLimit = 100_000_000
    static let savedEdgeLimit = 3_072
    static let previewEdgeLimit = 512
    private static let supportedTypes = [UTType.jpeg, .heic, .heif, .png].map(\.identifier)
    private static let savedQuality = 0.90
    private static let previewQuality = 0.70

    static func prepare(_ data: Data) throws -> PreparedPhoto {
        try Task.checkCancellation()
        let source = try validatedSource(data, byteLimit: inputByteLimit, edgeLimit: inputEdgeLimit)
        let pixels = try decode(source, edge: savedEdgeLimit)
        let properties = try properties(source)
        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        let saved: Data
        if data.count <= savedByteLimit, max(width, height) <= savedEdgeLimit {
            saved = data
        } else {
            let type = CGImageSourceGetType(source) as String?
            let outputType = type == UTType.png.identifier || hasAlpha(pixels)
                ? UTType.png : type == UTType.jpeg.identifier ? UTType.jpeg : UTType.heic
            saved = try encode(
                pixels,
                type: outputType,
                quality: savedQuality,
                metadata: normalizedMetadata(source, image: pixels)
            )
            let savedSource = try validatedSource(saved, byteLimit: savedByteLimit, edgeLimit: savedEdgeLimit)
            _ = try decode(savedSource, edge: savedEdgeLimit)
        }
        try Task.checkCancellation()
        // A derivative failure must not discard a successfully validated attachment.
        let preview = try? thumbnail(saved)
        return .init(imageData: saved, thumbnailData: preview)
    }

    static func thumbnail(_ data: Data) throws -> Data {
        let source = try validatedSource(data, byteLimit: savedByteLimit, edgeLimit: savedEdgeLimit)
        let image = try decode(source, edge: previewEdgeLimit)
        let result = try encode(
            image, type: hasAlpha(image) ? .png : .jpeg, quality: previewQuality, metadata: nil
        )
        guard result.count <= previewByteLimit else {
            throw RecordError.invalidPhoto
        }
        return result
    }

    static func display(_ data: Data, edge: Int) throws -> CGImage {
        let source = try validatedSource(data, byteLimit: savedByteLimit, edgeLimit: savedEdgeLimit)
        return try decode(source, edge: edge)
    }

    private static func validatedSource(_ data: Data, byteLimit: Int, edgeLimit: Int) throws -> CGImageSource {
        guard !data.isEmpty, data.count <= byteLimit,
              let source = CGImageSourceCreateWithData(
                data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary
              ),
              let type = CGImageSourceGetType(source) as String?,
              supportedTypes.contains(type),
              CGImageSourceGetCount(source) == 1,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete
        else {
            throw RecordError.invalidPhoto
        }
        let values = try properties(source)
        guard let width = values[kCGImagePropertyPixelWidth] as? Int,
              let height = values[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= edgeLimit, height <= edgeLimit,
              width <= inputPixelLimit / height
        else {
            throw RecordError.invalidPhoto
        }
        return source
    }

    private static func properties(_ source: CGImageSource) throws -> [CFString: Any] {
        guard let result = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            throw RecordError.invalidPhoto
        }
        return result
    }

    private static func decode(_ source: CGImageSource, edge: Int) throws -> CGImage {
        let values = try properties(source)
        guard let width = values[kCGImagePropertyPixelWidth] as? Int,
              let height = values[kCGImagePropertyPixelHeight] as? Int
        else {
            throw RecordError.invalidPhoto
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: min(edge, max(width, height)),
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceDecodeRequest: kCGImageSourceDecodeToSDR
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete
        else {
            throw RecordError.invalidPhoto
        }
        return image
    }

    private static func normalizedMetadata(_ source: CGImageSource, image: CGImage) throws -> CGImageMetadata? {
        guard let original = CGImageSourceCopyMetadataAtIndex(source, 0, nil) else {
            return nil
        }
        guard let metadata = CGImageMetadataCreateMutableCopy(original) else {
            throw RecordError.invalidPhoto
        }
        guard CGImageMetadataSetValueMatchingImageProperty(
            metadata, kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFOrientation, 1 as CFNumber
        ) else {
            throw RecordError.invalidPhoto
        }
        for (property, value) in [
            (kCGImagePropertyExifPixelXDimension, image.width),
            (kCGImagePropertyExifPixelYDimension, image.height)
        ] {
            guard CGImageMetadataSetValueMatchingImageProperty(
                metadata, kCGImagePropertyExifDictionary, property, value as CFNumber
            ) else {
                throw RecordError.invalidPhoto
            }
        }
        for (path, value) in [("tiff:ImageWidth", image.width), ("tiff:ImageLength", image.height)] {
            guard CGImageMetadataSetValueWithPath(metadata, nil, path as CFString, value as CFNumber) else {
                throw RecordError.invalidPhoto
            }
        }
        return metadata
    }

    private static func encode(
        _ image: CGImage, type: UTType, quality: Double, metadata: CGImageMetadata?
    ) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil) else {
            throw RecordError.invalidPhoto
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationEmbedThumbnail: false
        ]
        CGImageDestinationAddImageAndMetadata(destination, image, metadata, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw RecordError.invalidPhoto
        }
        return output as Data
    }

    private static func hasAlpha(_ image: CGImage) -> Bool {
        [.first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly].contains(image.alphaInfo)
    }
}
