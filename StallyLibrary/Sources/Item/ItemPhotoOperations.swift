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

    private static let jpegCompressionQuality = 0.8
    private static let bitsPerComponent = 8

    /// Downsamples image data, applies its orientation, and returns a metadata-free JPEG.
    public static func prepare(_ photoData: Data) throws -> Data {
        guard photoData.count <= maximumSourceDataByteCount else {
            throw ItemValidationError.photoTooLarge
        }

        guard let source = imageSource(from: photoData),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(
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

    /// Validates that optional data is a bounded, decodable item photo.
    public static func validate(_ photoData: Data?) throws {
        guard let photoData else {
            return
        }

        guard photoData.count <= maximumDataByteCount else {
            throw ItemValidationError.photoTooLarge
        }

        guard let source = imageSource(from: photoData),
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

        guard CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions
        ) != nil else {
            throw ItemValidationError.photoUnreadable
        }
    }
}

private extension ItemPhotoOperations {
    static var thumbnailOptions: CFDictionary {
        [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelDimension
        ] as CFDictionary
    }

    static func imageSource(from photoData: Data) -> CGImageSource? {
        CGImageSourceCreateWithData(
            photoData as CFData,
            [kCGImageSourceShouldCache: false] as CFDictionary
        )
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
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
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
