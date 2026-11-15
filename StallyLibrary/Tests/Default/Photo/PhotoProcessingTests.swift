import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import StallyLibrary

struct PhotoProcessingTests {
    @Test(arguments: [UTType.jpeg.identifier, UTType.heic.identifier])
    func supportedLossyFormatsPreserveOrTransformAsRequired(_ identifier: String) async throws {
        let type = try #require(UTType(identifier))
        let small = try PhotoTestImages.imageData(type: type, hasAlpha: false)
        let retained = try await PhotoOperations.prepare(data: small)
        #expect(retained.imageData == small)
        let large = try PhotoTestImages.imageData(width: 3_074, height: 768, type: type, hasAlpha: false)
        let transformed = try await PhotoOperations.prepare(data: large)
        let source = try #require(CGImageSourceCreateWithData(transformed.imageData as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == identifier)
        let image = try await PhotoOperations.image(data: transformed.imageData)
        #expect(image.width == 3_072)
        // Downsampling and native HEIC encoding each round raster dimensions.
        #expect(abs(image.height - 768) <= 2)
        #expect(transformed.imageData.count <= PhotoProcessor.savedByteLimit)
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let exif = try #require(properties[kCGImagePropertyExifDictionary] as? [CFString: Any])
        #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String == "2020:02:03 04:05:06")
    }

    @Test
    func qualifyingBytesRemainIdenticalAndPreviewIsIndependent() async throws {
        let original = try PhotoTestImages.imageData()
        let prepared = try await PhotoOperations.prepare(data: original)
        #expect(prepared.imageData == original)
        #expect(prepared.thumbnailData != nil)
        let image = try await PhotoOperations.image(data: prepared.imageData)
        #expect(image.width == 24 && image.height == 12)
        #expect([.premultipliedFirst, .first, .premultipliedLast, .last].contains(image.alphaInfo))
    }

    @Test
    func oversizedImageIsResizedAndDescriptiveMetadataRetained() async throws {
        let input = try PhotoTestImages.imageData(width: 3_073, height: 12, orientation: 6)
        let prepared = try await PhotoOperations.prepare(data: input)
        #expect(prepared.imageData != input)
        let source = try #require(CGImageSourceCreateWithData(prepared.imageData as CFData, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 12)
        #expect(properties[kCGImagePropertyPixelHeight] as? Int == 3_072)
        let exif = try #require(properties[kCGImagePropertyExifDictionary] as? [CFString: Any])
        #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String == "2020:02:03 04:05:06")
        #expect(exif[kCGImagePropertyExifPixelXDimension] as? Int == 12)
        #expect(exif[kCGImagePropertyExifPixelYDimension] as? Int == 3_072)
        #expect(prepared.thumbnailData != nil)
    }

    @Test
    func invalidOrUnsupportedPhotosDoNotProduceAttachments() async throws {
        await #expect(throws: RecordError.invalidPhoto) {
            try await PhotoOperations.prepare(data: Data("not an image".utf8))
        }
        let png = try PhotoTestImages.imageData()
        await #expect(throws: RecordError.invalidPhoto) {
            try await PhotoOperations.prepare(data: Data(png.prefix(png.count / 2)))
        }
        let tiff = try PhotoTestImages.imageData(type: .tiff)
        await #expect(throws: RecordError.invalidPhoto) {
            try await PhotoOperations.prepare(data: tiff)
        }
    }
}
