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
            includesSourceMetadata: true
        )

        let preparedData = try ItemPhotoOperations.prepare(sourceData)
        let properties = try TestPhotoInspection.properties(in: preparedData)

        #expect(properties.width == 800)
        #expect(properties.height == ItemPhotoOperations.maximumPixelDimension)
        #expect(properties.orientation == nil || properties.orientation == 1)
        #expect(!properties.containsSourceMetadata)
        #expect(!properties.containsAlpha)
        #expect(preparedData.count <= ItemPhotoOperations.maximumDataByteCount)
        #expect(properties.typeIdentifier == UTType.jpeg.identifier)
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
        let sourceData = try TestPhotoFixtures.blackPNGData(
            width: 100,
            height: 50,
            alpha: 0.5
        )

        let preparedData = try ItemPhotoOperations.prepare(sourceData)
        let properties = try TestPhotoInspection.properties(in: preparedData)
        let pixel = try TestPhotoInspection.pixel(
            in: preparedData,
            normalizedX: 0.5,
            normalizedY: 0.5
        )

        #expect(!properties.containsAlpha)
        #expect(properties.typeIdentifier == UTType.jpeg.identifier)
        #expect(abs(pixel.red - 0.5) < 0.05)
        #expect(abs(pixel.green - 0.5) < 0.05)
        #expect(abs(pixel.blue - 0.5) < 0.05)
    }

    @Test
    func `prepare preserves canonical JPEG bytes`() throws {
        let preparedData = try TestPhotoFixtures.preparedData()

        #expect(try ItemPhotoOperations.prepare(preparedData) == preparedData)
    }

    @Test
    func `prepare applies every image orientation to pixels`() throws {
        let referenceData = try ItemPhotoOperations.prepare(
            TestPhotoFixtures.asymmetricJPEGData(orientation: .up)
        )
        let referenceCorners = try TestPhotoInspection.cornerColors(in: referenceData)

        for orientation in TestPhotoInspection.orientations {
            let preparedData = try ItemPhotoOperations.prepare(
                TestPhotoFixtures.asymmetricJPEGData(orientation: orientation)
            )
            let actualCorners = try TestPhotoInspection.cornerColors(in: preparedData)

            #expect(
                actualCorners == referenceCorners.applying(orientation),
                "Orientation raw value: \(orientation.rawValue)"
            )
        }
    }

    @Test
    func `prepare rejects multiple frames and excessive source pixels`() throws {
        let multipleFrameData = try TestPhotoFixtures.tiffData(frameCount: 2)
        let excessiveDimensionData = try TestPhotoFixtures.jpegDataReporting(
            width: ItemPhotoOperations.maximumSourcePixelDimension + 1,
            height: 1
        )
        let excessivePixelCountData = try TestPhotoFixtures.jpegDataReporting(
            width: 10_001,
            height: 10_000
        )

        #expect(throws: ItemValidationError.photoUnreadable) {
            try ItemPhotoOperations.prepare(multipleFrameData)
        }
        #expect(throws: ItemValidationError.photoTooLarge) {
            try ItemPhotoOperations.prepare(excessiveDimensionData)
        }
        #expect(throws: ItemValidationError.self) {
            try ItemPhotoOperations.prepare(excessivePixelCountData)
        }
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
