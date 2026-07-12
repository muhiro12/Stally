//
//  TestPhotoInspection.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import CoreGraphics
import Foundation
import ImageIO

enum TestPhotoInspection {
    struct CornerColors: Equatable {
        let topLeft: SampleColor
        let topRight: SampleColor
        let bottomLeft: SampleColor
        let bottomRight: SampleColor

        private var mirroredHorizontally: Self {
            .init(
                topLeft: topRight,
                topRight: topLeft,
                bottomLeft: bottomRight,
                bottomRight: bottomLeft
            )
        }

        private var mirroredVertically: Self {
            .init(
                topLeft: bottomLeft,
                topRight: bottomRight,
                bottomLeft: topLeft,
                bottomRight: topRight
            )
        }

        private var rotatedHalfTurn: Self {
            .init(
                topLeft: bottomRight,
                topRight: bottomLeft,
                bottomLeft: topRight,
                bottomRight: topLeft
            )
        }

        private var rotatedLeft: Self {
            .init(
                topLeft: topRight,
                topRight: bottomRight,
                bottomLeft: topLeft,
                bottomRight: bottomLeft
            )
        }

        private var rotatedRight: Self {
            .init(
                topLeft: bottomLeft,
                topRight: topLeft,
                bottomLeft: bottomRight,
                bottomRight: topRight
            )
        }

        private var transposed: Self {
            .init(
                topLeft: topLeft,
                topRight: bottomLeft,
                bottomLeft: topRight,
                bottomRight: bottomRight
            )
        }

        private var transversed: Self {
            .init(
                topLeft: bottomRight,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: topLeft
            )
        }

        func applying(_ orientation: CGImagePropertyOrientation) -> Self {
            switch orientation {
            case .up:
                self
            case .upMirrored:
                mirroredHorizontally
            case .down:
                rotatedHalfTurn
            case .downMirrored:
                mirroredVertically
            case .leftMirrored:
                transposed
            case .right:
                rotatedRight
            case .rightMirrored:
                transversed
            case .left:
                rotatedLeft
            }
        }
    }

    struct Properties {
        let width: Int
        let height: Int
        let typeIdentifier: String
        let orientation: Int?
        let containsSourceMetadata: Bool
        let containsAlpha: Bool
    }

    struct Pixel {
        let red: Double
        let green: Double
        let blue: Double

        var sampleColor: SampleColor {
            if red > yellowThreshold, green > yellowThreshold {
                return .yellow
            }

            if red > green, red > blue {
                return .red
            }

            if green > blue {
                return .green
            }

            return .blue
        }
    }

    enum SampleColor: Equatable {
        case blue
        case green
        case red
        case yellow
    }

    enum InspectionError: Error {
        case unreadableImage
    }

    static let orientations: [CGImagePropertyOrientation] = [
        .up,
        .upMirrored,
        .down,
        .downMirrored,
        .leftMirrored,
        .right,
        .rightMirrored,
        .left
    ]

    private static let bitsPerComponent = 8
    private static let bytesPerPixel = 4
    private static let blueComponentOffset = 0
    private static let greenComponentOffset = 1
    private static let redComponentOffset = 2
    private static let topLeftPixelIndex = 0
    private static let topRightPixelIndex = 1
    private static let bottomLeftPixelIndex = 2
    private static let bottomRightPixelIndex = 3
    private static let maximumComponentValue = 255.0
    private static let nearEdgeSample = 0.25
    private static let farEdgeSample = 0.75
    private static let yellowThreshold = 0.7
    private static let sRGBExifColorSpace = 1

    static func properties(in data: Data) throws -> Properties {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let typeIdentifier = CGImageSourceGetType(source) as String?,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw InspectionError.unreadableImage
        }

        return .init(
            width: width,
            height: height,
            typeIdentifier: typeIdentifier,
            orientation: properties[kCGImagePropertyOrientation] as? Int,
            containsSourceMetadata: containsSourceMetadata(in: source),
            containsAlpha: properties[kCGImagePropertyHasAlpha] as? Bool ?? false
        )
    }

    static func cornerColors(in data: Data) throws -> CornerColors {
        let pixels = try pixels(
            in: data,
            normalizedPoints: [
                .init(x: nearEdgeSample, y: nearEdgeSample),
                .init(x: farEdgeSample, y: nearEdgeSample),
                .init(x: nearEdgeSample, y: farEdgeSample),
                .init(x: farEdgeSample, y: farEdgeSample)
            ]
        )

        guard pixels.count == bytesPerPixel else {
            throw InspectionError.unreadableImage
        }

        return .init(
            topLeft: pixels[topLeftPixelIndex].sampleColor,
            topRight: pixels[topRightPixelIndex].sampleColor,
            bottomLeft: pixels[bottomLeftPixelIndex].sampleColor,
            bottomRight: pixels[bottomRightPixelIndex].sampleColor
        )
    }

    static func pixel(
        in data: Data,
        normalizedX: Double,
        normalizedY: Double
    ) throws -> Pixel {
        guard let pixel = try pixels(
            in: data,
            normalizedPoints: [.init(x: normalizedX, y: normalizedY)]
        ).first else {
            throw InspectionError.unreadableImage
        }

        return pixel
    }
}

private extension TestPhotoInspection {
    static func containsSourceMetadata(in source: CGImageSource) -> Bool {
        guard let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil),
              let tags = CGImageMetadataCopyTags(metadata) as? [CGImageMetadataTag] else {
            return false
        }

        return tags.contains { tag in
            guard CGImageMetadataTagCopyNamespace(tag) as String?
                    == kCGImageMetadataNamespaceExif as String,
                  let name = CGImageMetadataTagCopyName(tag) as String? else {
                return true
            }

            if name == (kCGImagePropertyExifPixelXDimension as String)
                || name == (kCGImagePropertyExifPixelYDimension as String) {
                return false
            }

            if name == (kCGImagePropertyExifColorSpace as String) {
                return metadataIntegerValue(tag) != sRGBExifColorSpace
            }

            return true
        }
    }

    static func metadataIntegerValue(_ tag: CGImageMetadataTag) -> Int? {
        guard let value = CGImageMetadataTagCopyValue(tag) else {
            return nil
        }

        return Int(String(describing: value))
    }

    static func pixels(
        in data: Data,
        normalizedPoints: [CGPoint]
    ) throws -> [Pixel] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw InspectionError.unreadableImage
        }

        let bytesPerRow = image.width * bytesPerPixel
        var buffer = Data(count: bytesPerRow * image.height)

        return try buffer.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress,
                  let context = pixelContext(
                    data: baseAddress,
                    image: image,
                    bytesPerRow: bytesPerRow
                  ) else {
                throw InspectionError.unreadableImage
            }

            context.draw(
                image,
                in: .init(x: 0, y: 0, width: image.width, height: image.height)
            )
            let components = bytes.bindMemory(to: UInt8.self)

            return normalizedPoints.map { point in
                let column = min(image.width - 1, Int(point.x * Double(image.width)))
                let row = min(image.height - 1, Int(point.y * Double(image.height)))
                let offset = (row * bytesPerRow) + (column * bytesPerPixel)

                return .init(
                    red: Double(components[offset + redComponentOffset])
                        / maximumComponentValue,
                    green: Double(components[offset + greenComponentOffset])
                        / maximumComponentValue,
                    blue: Double(components[offset + blueComponentOffset])
                        / maximumComponentValue
                )
            }
        }
    }

    static func pixelContext(
        data: UnsafeMutableRawPointer,
        image: CGImage,
        bytesPerRow: Int
    ) -> CGContext? {
        CGContext(
            data: data,
            width: image.width,
            height: image.height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                | CGBitmapInfo.byteOrder32Little.rawValue
        )
    }
}
