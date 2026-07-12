//
//  ItemPhotoOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import Foundation
import ImageIO
import StallyLibrary
import Testing
import UniformTypeIdentifiers

@Suite
struct ItemPhotoOperationsTests {
    @Test
    func `prepare applies orientation downsamples and strips metadata`() throws {
        let sourceData = try TestPhotoFixtures.jpegData(
            width: 2_000,
            height: 1_000,
            orientation: .right,
            includesLocationMetadata: true
        )

        let preparedData = try ItemPhotoOperations.prepare(sourceData)
        let properties = try imageProperties(in: preparedData)

        #expect(properties.width == 800)
        #expect(properties.height == ItemPhotoOperations.maximumPixelDimension)
        #expect(properties.orientation == nil || properties.orientation == 1)
        #expect(!properties.containsLocationMetadata)
        #expect(!properties.containsAlpha)
        #expect(preparedData.count <= ItemPhotoOperations.maximumDataByteCount)
        #expect(try imageType(in: preparedData) == UTType.jpeg.identifier)
    }

    @Test
    func `validate accepts nil and prepared image data`() throws {
        try ItemPhotoOperations.validate(nil)
        try ItemPhotoOperations.validate(TestPhotoFixtures.preparedData())
    }

    @Test
    func `prepare and validate reject unreadable data`() {
        let unreadableData = Data([0x01, 0x02, 0x03])

        #expect(throws: ItemValidationError.photoUnreadable) {
            try ItemPhotoOperations.prepare(unreadableData)
        }
        #expect(throws: ItemValidationError.photoUnreadable) {
            try ItemPhotoOperations.validate(unreadableData)
        }
    }

    @Test
    func `prepare rejects an excessive source payload before decoding`() {
        let excessiveSourceData = Data(
            repeating: 0,
            count: ItemPhotoOperations.maximumSourceDataByteCount + 1
        )

        #expect(throws: ItemValidationError.photoTooLarge) {
            try ItemPhotoOperations.prepare(excessiveSourceData)
        }
    }

    @Test
    func `prepare flattens source transparency into JPEG data`() throws {
        let sourceData = try TestPhotoFixtures.pngData(
            width: 100,
            height: 50,
            alpha: 0.5
        )

        let preparedData = try ItemPhotoOperations.prepare(sourceData)
        let properties = try imageProperties(in: preparedData)

        #expect(!properties.containsAlpha)
        #expect(try imageType(in: preparedData) == UTType.jpeg.identifier)
    }

    @Test
    func `validate rejects excessive dimensions and encoded size`() throws {
        let excessiveDimensionData = try TestPhotoFixtures.jpegData(
            width: ItemPhotoOperations.maximumPixelDimension + 1,
            height: 1
        )
        let preparedData = try TestPhotoFixtures.preparedData()
        let excessiveByteCount = ItemPhotoOperations.maximumDataByteCount - preparedData.count + 1
        let excessiveSizeData = preparedData + Data(repeating: 0, count: excessiveByteCount)

        #expect(throws: ItemValidationError.photoTooLarge) {
            try ItemPhotoOperations.validate(excessiveDimensionData)
        }
        #expect(throws: ItemValidationError.photoTooLarge) {
            try ItemPhotoOperations.validate(excessiveSizeData)
        }
    }
}

private extension ItemPhotoOperationsTests {
    struct ImageProperties {
        let width: Int
        let height: Int
        let orientation: Int?
        let containsLocationMetadata: Bool
        let containsAlpha: Bool
    }

    enum ImageInspectionError: Error {
        case unreadableImage
    }

    func imageProperties(in data: Data) throws -> ImageProperties {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw ImageInspectionError.unreadableImage
        }

        return .init(
            width: width,
            height: height,
            orientation: properties[kCGImagePropertyOrientation] as? Int,
            containsLocationMetadata: properties[kCGImagePropertyGPSDictionary] != nil,
            containsAlpha: properties[kCGImagePropertyHasAlpha] as? Bool ?? false
        )
    }

    func imageType(in data: Data) throws -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) else {
            throw ImageInspectionError.unreadableImage
        }

        return type as String
    }
}
