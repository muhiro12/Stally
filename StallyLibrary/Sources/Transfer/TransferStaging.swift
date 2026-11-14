import Darwin
import Foundation

/// Owns private files through review, writing, and any mapped Data retained by SwiftData.
final class TransferStaging: Sendable {
    let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appending(path: "StallyTransfer-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700]
        )
        do {
            try FileManager.default.createDirectory(
                at: directory.appending(path: "assets"),
                withIntermediateDirectories: false
            )
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    static func checkSpace(bytes: Int, at url: URL) throws {
        let capacity = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        if let available = capacity.volumeAvailableCapacityForImportantUsage, available < Int64(bytes) {
            throw CocoaError(.fileWriteOutOfSpace)
        }
    }

    func write(_ data: Data, path: String) throws {
        try Task.checkCancellation()
        try Self.checkSpace(bytes: data.count, at: directory)
        try data.write(to: directory.appending(path: path), options: .withoutOverwriting)
    }

    /// mmap must succeed: a Foundation mapping hint may silently allocate all pending photos.
    /// Private writable pages preserve Data value semantics without changing staged files.
    /// The lease stays alive until the returned Data releases the mapping.
    func data(path: String) throws -> Data {
        let descriptor = open(directory.appending(path: path).path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        defer { close(descriptor) }
        var info = stat()
        guard fstat(descriptor, &info) == 0, info.st_mode & S_IFMT == S_IFREG, info.st_size >= 0,
              let count = Int(exactly: info.st_size)
        else { throw TransferError.invalidFile }
        guard count > 0 else {
            return Data()
        }
        guard let address = mmap(nil, count, PROT_READ | PROT_WRITE, MAP_PRIVATE, descriptor, 0), address != MAP_FAILED
        else {
            throw POSIXError(.init(rawValue: errno) ?? .ENOMEM)
        }
        return Data(
            bytesNoCopy: address,
            count: count,
            deallocator: .custom { [self] address, length in
                munmap(address, length)
                withExtendedLifetime(self) {
                    // The mapped Data owns this directory until it releases the mapping.
                }
            }
        )
    }

    deinit { try? FileManager.default.removeItem(at: directory) }
}
