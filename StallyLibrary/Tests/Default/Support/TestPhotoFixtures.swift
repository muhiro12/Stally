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
    private enum FixtureError: Error {
        case imageCreationFailed
    }

    private static let preparedWidth = 64
    private static let preparedHeight = 48
    private static let bitsPerComponent = 8
    private static let redComponent = 0.12
    private static let greenComponent = 0.33
    private static let blueComponent = 0.30
    private static let opaqueAlpha = 1.0
    private static let maximumCompressionQuality = 1.0
    private static let latitude = 35.0
    private static let longitude = 139.0

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
            includesLocationMetadata: false
        )
    }

    static func jpegData(
        width: Int,
        height: Int,
        orientation: CGImagePropertyOrientation,
        includesLocationMetadata: Bool
    ) throws -> Data {
        let image = try image(width: width, height: height, alpha: opaqueAlpha)

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

        if includesLocationMetadata {
            properties[kCGImagePropertyGPSDictionary] = [
                kCGImagePropertyGPSLatitude: latitude,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: longitude,
                kCGImagePropertyGPSLongitudeRef: "E"
            ]
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

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
        let image = try image(width: width, height: height, alpha: alpha)
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
}

private extension TestPhotoFixtures {
    static func image(
        width: Int,
        height: Int,
        alpha: Double
    ) throws -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw FixtureError.imageCreationFailed
        }

        context.setFillColor(
            red: redComponent,
            green: greenComponent,
            blue: blueComponent,
            alpha: alpha
        )
        context.fill(.init(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else {
            throw FixtureError.imageCreationFailed
        }

        return image
    }
}
