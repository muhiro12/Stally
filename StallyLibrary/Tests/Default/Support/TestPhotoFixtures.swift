//
//  TestPhotoFixtures.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import CoreGraphics
import Foundation
import ImageIO
import StallyLibrary
import UniformTypeIdentifiers

enum TestPhotoFixtures {
    struct ColorComponents {
        let red: Double
        let green: Double
        let blue: Double
    }

    private enum FixtureError: Error {
        case imageCreationFailed
    }

    private static let asymmetricHeight = 80
    private static let asymmetricWidth = 120
    private static let preparedWidth = 64
    private static let preparedHeight = 48
    private static let bitsPerComponent = 8
    private static let defaultRedComponent = 0.12
    private static let defaultGreenComponent = 0.33
    private static let defaultBlueComponent = 0.30
    private static let defaultColor = ColorComponents(
        red: defaultRedComponent,
        green: defaultGreenComponent,
        blue: defaultBlueComponent
    )
    private static let blackColor = ColorComponents(red: 0, green: 0, blue: 0)
    private static let opaqueAlpha = 1.0
    private static let maximumCompressionQuality = 1.0
    private static let latitude = 35.0
    private static let longitude = 139.0
    private static let metadataDate = "2026:07:12 12:00:00"
    private static let metadataText = "Private fixture metadata"
    private static let jpegBaselineStartOfFrameMarker: UInt8 = 0xC0
    private static let jpegMarkerPrefix: UInt8 = 0xFF
    private static let jpegHeaderLookaheadByteCount = 8
    private static let jpegHeightByteOffset = 5
    private static let jpegWidthByteOffset = 7
    private static let byteBitShift = 8
    private static let byteMask = 0xFF
    private static let pixelBombFixtureDimension = 2
    private static let quadrantDivisor = 2
    private static let redColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
    private static let greenColor = CGColor(red: 0, green: 1, blue: 0, alpha: 1)
    private static let blueColor = CGColor(red: 0, green: 0, blue: 1, alpha: 1)
    private static let yellowColor = CGColor(red: 1, green: 1, blue: 0, alpha: 1)

    static func preparedData() throws -> Data {
        try ItemPhotoOperations.prepare(
            jpegData(width: preparedWidth, height: preparedHeight)
        )
    }

    static func jpegData(
        width: Int,
        height: Int
    ) throws -> Data {
        try jpegData(
            width: width,
            height: height,
            orientation: .up,
            includesSourceMetadata: false
        )
    }

    static func jpegData(
        width: Int,
        height: Int,
        orientation: CGImagePropertyOrientation,
        includesSourceMetadata: Bool
    ) throws -> Data {
        let image = try image(width: width, height: height, alpha: opaqueAlpha)

        return try jpegData(
            image: image,
            orientation: orientation,
            includesSourceMetadata: includesSourceMetadata
        )
    }

    static func asymmetricJPEGData(
        orientation: CGImagePropertyOrientation
    ) throws -> Data {
        try jpegData(
            image: quadrantImage(width: asymmetricWidth, height: asymmetricHeight),
            orientation: orientation,
            includesSourceMetadata: false
        )
    }

    static func jpegDataReporting(
        width: Int,
        height: Int
    ) throws -> Data {
        var data = try jpegData(
            width: pixelBombFixtureDimension,
            height: pixelBombFixtureDimension
        )
        let startIndex = data.startIndex
        let endIndex = data.index(
            data.endIndex,
            offsetBy: -jpegHeaderLookaheadByteCount
        )

        guard let markerIndex = data.indices[startIndex..<endIndex].first(where: { index in
            data[index] == jpegMarkerPrefix
                && data[data.index(after: index)] == jpegBaselineStartOfFrameMarker
        }) else {
            throw FixtureError.imageCreationFailed
        }

        let heightIndex = data.index(markerIndex, offsetBy: jpegHeightByteOffset)
        let widthIndex = data.index(markerIndex, offsetBy: jpegWidthByteOffset)
        data[heightIndex] = UInt8((height >> byteBitShift) & byteMask)
        data[data.index(after: heightIndex)] = UInt8(height & byteMask)
        data[widthIndex] = UInt8((width >> byteBitShift) & byteMask)
        data[data.index(after: widthIndex)] = UInt8(width & byteMask)
        return data
    }

    static func tiffData(frameCount: Int) throws -> Data {
        let image = try image(width: preparedWidth, height: preparedHeight, alpha: opaqueAlpha)
        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.tiff.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw FixtureError.imageCreationFailed
        }

        for _ in 0..<frameCount {
            CGImageDestinationAddImage(destination, image, nil)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError.imageCreationFailed
        }

        return data as Data
    }

    static func pngData(
        width: Int,
        height: Int,
        alpha: Double
    ) throws -> Data {
        try pngData(
            width: width,
            height: height,
            color: defaultColor,
            alpha: alpha
        )
    }

    static func blackPNGData(
        width: Int,
        height: Int,
        alpha: Double
    ) throws -> Data {
        try pngData(
            width: width,
            height: height,
            color: blackColor,
            alpha: alpha
        )
    }
}

private extension TestPhotoFixtures {
    static func pngData(
        width: Int,
        height: Int,
        color: ColorComponents,
        alpha: Double
    ) throws -> Data {
        let image = try image(
            width: width,
            height: height,
            color: color,
            alpha: alpha
        )
        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw FixtureError.imageCreationFailed
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError.imageCreationFailed
        }

        return data as Data
    }
    static func jpegData(
        image: CGImage,
        orientation: CGImagePropertyOrientation,
        includesSourceMetadata: Bool
    ) throws -> Data {
        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw FixtureError.imageCreationFailed
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: maximumCompressionQuality,
            kCGImagePropertyOrientation: orientation.rawValue
        ]

        if includesSourceMetadata {
            properties[kCGImagePropertyGPSDictionary] = [
                kCGImagePropertyGPSLatitude: latitude,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: longitude,
                kCGImagePropertyGPSLongitudeRef: "E"
            ]
            properties[kCGImagePropertyExifDictionary] = [
                kCGImagePropertyExifDateTimeOriginal: metadataDate,
                kCGImagePropertyExifUserComment: metadataText
            ]
            properties[kCGImagePropertyIPTCDictionary] = [
                kCGImagePropertyIPTCCaptionAbstract: metadataText
            ]
            properties[kCGImagePropertyTIFFDictionary] = [
                kCGImagePropertyTIFFMake: metadataText
            ]
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError.imageCreationFailed
        }

        return data as Data
    }

    static func image(
        width: Int,
        height: Int,
        alpha: Double
    ) throws -> CGImage {
        try image(
            width: width,
            height: height,
            color: defaultColor,
            alpha: alpha
        )
    }

    static func image(
        width: Int,
        height: Int,
        color: ColorComponents,
        alpha: Double
    ) throws -> CGImage {
        let alphaInfo: CGImageAlphaInfo = if alpha < opaqueAlpha {
            .premultipliedLast
        } else {
            .noneSkipLast
        }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: alphaInfo.rawValue
        ) else {
            throw FixtureError.imageCreationFailed
        }

        context.setFillColor(
            red: color.red,
            green: color.green,
            blue: color.blue,
            alpha: alpha
        )
        context.fill(.init(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else {
            throw FixtureError.imageCreationFailed
        }

        return image
    }

    static func quadrantImage(
        width: Int,
        height: Int
    ) throws -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            throw FixtureError.imageCreationFailed
        }

        let halfWidth = width / quadrantDivisor
        let halfHeight = height / quadrantDivisor
        let quadrants: [(CGRect, CGColor)] = [
            (
                .init(x: 0, y: halfHeight, width: halfWidth, height: halfHeight),
                redColor
            ),
            (
                .init(x: halfWidth, y: halfHeight, width: halfWidth, height: halfHeight),
                greenColor
            ),
            (
                .init(x: 0, y: 0, width: halfWidth, height: halfHeight),
                blueColor
            ),
            (
                .init(x: halfWidth, y: 0, width: halfWidth, height: halfHeight),
                yellowColor
            )
        ]

        for (rectangle, color) in quadrants {
            context.setFillColor(color)
            context.fill(rectangle)
        }

        guard let image = context.makeImage() else {
            throw FixtureError.imageCreationFailed
        }

        return image
    }
}
