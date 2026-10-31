import CryptoKit
import Foundation
import UniformTypeIdentifiers

/// Restoration checks the saved representation without ingesting or re-encoding it.
enum TransferMedia {
    static func fileExtension(_ data: Data) throws -> String {
        let type = try PhotoOperations.contentType(of: data).identifier
        switch type {
        case UTType.jpeg.identifier:
            return "jpg"
        case UTType.png.identifier:
            return "png"
        case UTType.heic.identifier:
            return "heic"
        case UTType.heif.identifier:
            return "heif"
        default:
            throw RecordError.invalidPhoto
        }
    }

    static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func validate(_ data: Data, image: TransferImage) throws {
        guard data.count == image.byteCount, digest(data) == image.sha256,
              let path = image.path, try path.hasSuffix(".\(fileExtension(data))")
        else {
            throw TransferError.invalidFile
        }
    }
}
