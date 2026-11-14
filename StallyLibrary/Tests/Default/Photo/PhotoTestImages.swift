import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

// Fixture defaults and numeric components describe synthetic test pixels.
// swiftlint:disable discouraged_default_parameter no_magic_numbers

enum PhotoTestImages {
    static func imageData(
        width: Int = 24,
        height: Int = 12,
        orientation: Int = 1,
        type: UTType = .png,
        hasAlpha: Bool = true
    ) throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = try #require(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: (hasAlpha ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast).rawValue
        ))
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: hasAlpha ? 0.5 : 1))
        context.fill(.init(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let output = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil))
        let properties: [CFString: Any] = [
            kCGImagePropertyOrientation: orientation,
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2020:02:03 04:05:06"]
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return output as Data
    }
}

// swiftlint:enable discouraged_default_parameter no_magic_numbers
