//
//  ItemPhotoOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/12.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Prepares and validates the durable photo data attached to an item.
public enum ItemPhotoOperations {
    /// Largest supported width or height for a stored item photo.
    public static let maximumPixelDimension = 1_600
    /// Largest supported encoded size for a stored item photo.
    public static let maximumDataByteCount = 2_097_152
    /// Largest source payload accepted before image decoding begins.
    public static let maximumSourceDataByteCount = 67_108_864
    /// Largest supported width or height reported by a source image.
    public static let maximumSourcePixelDimension = 16_384
    /// Largest supported source image area before downsampling.
    public static let maximumSourcePixelCount = 100_000_000

    private static let jpegCompressionQuality = 0.8
    private static let bitsPerComponent = 8
    private static let sRGBExifColorSpace = 1
    private static let jpegMarkerPrefix: UInt8 = 0xFF
    private static let jpegEndOfImageMarker: UInt8 = 0xD9
    private static let canonicalJPEGEndMarker = Data([
        jpegMarkerPrefix,
        jpegEndOfImageMarker
    ])
    private static let supportedSourceTypeIdentifiers: Set<String> = [
        UTType.heic.identifier,
        UTType.heif.identifier,
        UTType.jpeg.identifier,
        UTType.png.identifier,
        UTType.tiff.identifier
    ]

    /// Returns canonical item photo data, preserving an already-canonical JPEG unchanged.
    ///
    /// Other supported still images are downsampled, orientation-normalized, flattened onto
    /// white, converted to sRGB JPEG, and stripped of source metadata.
    public static func prepare(_ photoData: Data) throws -> Data {
        if (try? validate(photoData)) != nil {
            return photoData
        }

        let source = try sourceImage(from: photoData)

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions
        ),
        let image = opaqueImage(from: thumbnail) else {
            throw ItemValidationError.photoUnreadable
        }

        let destinationData = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            destinationData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ItemValidationError.photoUnreadable
        }

        let destinationProperties = [
            kCGImageDestinationLossyCompressionQuality: jpegCompressionQuality
        ] as CFDictionary
        CGImageDestinationAddImage(destination, image, destinationProperties)

        guard CGImageDestinationFinalize(destination) else {
            throw ItemValidationError.photoUnreadable
        }

        let preparedData = destinationData as Data
        try validate(preparedData)
        return preparedData
    }

    /// Validates that optional data uses the canonical item photo representation.
    public static func validate(_ photoData: Data?) throws {
        guard let photoData else {
            return
        }

        guard photoData.count <= maximumDataByteCount else {
            throw ItemValidationError.photoTooLarge
        }

        guard photoData.suffix(canonicalJPEGEndMarker.count) == canonicalJPEGEndMarker,
              let source = imageSource(from: photoData),
              CGImageSourceGetCount(source) == 1,
              CGImageSourceGetType(source) as String? == UTType.jpeg.identifier,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw ItemValidationError.photoUnreadable
        }

        guard width > 0,
              height > 0,
              width <= maximumPixelDimension,
              height <= maximumPixelDimension else {
            throw ItemValidationError.photoTooLarge
        }

        guard properties[kCGImagePropertyOrientation] == nil,
              properties[kCGImagePropertyHasAlpha] as? Bool != true,
              containsOnlyGeneratedMetadata(
                source,
                width: width,
                height: height
              ),
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            throw ItemValidationError.photoUnreadable
        }
    }
}

private extension ItemPhotoOperations {
    static var thumbnailOptions: CFDictionary {
        [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelDimension,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
    }

    static func imageSource(from photoData: Data) -> CGImageSource? {
        CGImageSourceCreateWithData(
            photoData as CFData,
            [kCGImageSourceShouldCache: false] as CFDictionary
        )
    }

    static func sourceImage(from photoData: Data) throws -> CGImageSource {
        guard photoData.count <= maximumSourceDataByteCount else {
            throw ItemValidationError.photoTooLarge
        }

        guard let source = imageSource(from: photoData),
              CGImageSourceGetCount(source) == 1,
              let typeIdentifier = CGImageSourceGetType(source) as String?,
              supportedSourceTypeIdentifiers.contains(typeIdentifier),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw ItemValidationError.photoUnreadable
        }

        guard width > 0,
              height > 0,
              width <= maximumSourcePixelDimension,
              height <= maximumSourcePixelDimension,
              width <= maximumSourcePixelCount / height else {
            throw ItemValidationError.photoTooLarge
        }

        return source
    }

    static func containsOnlyGeneratedMetadata(
        _ source: CGImageSource,
        width: Int,
        height: Int
    ) -> Bool {
        guard let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil),
              let tags = CGImageMetadataCopyTags(metadata) as? [CGImageMetadataTag] else {
            return true
        }

        return tags.allSatisfy { tag in
            guard CGImageMetadataTagCopyNamespace(tag) as String?
                    == kCGImageMetadataNamespaceExif as String,
                  let name = CGImageMetadataTagCopyName(tag) as String? else {
                return false
            }

            if name == (kCGImagePropertyExifPixelXDimension as String) {
                return metadataIntegerValue(tag) == width
            }

            if name == (kCGImagePropertyExifPixelYDimension as String) {
                return metadataIntegerValue(tag) == height
            }

            if name == (kCGImagePropertyExifColorSpace as String) {
                return metadataIntegerValue(tag) == sRGBExifColorSpace
            }

            return false
        }
    }

    static func metadataIntegerValue(_ tag: CGImageMetadataTag) -> Int? {
        guard let value = CGImageMetadataTagCopyValue(tag) else {
            return nil
        }

        return Int(String(describing: value))
    }

    static func opaqueImage(from image: CGImage) -> CGImage? {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            ?? CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }

        context.setFillColor(gray: 1, alpha: 1)
        context.fill(.init(x: 0, y: 0, width: image.width, height: image.height))
        context.interpolationQuality = .high
        context.draw(image, in: .init(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage()
    }
}
