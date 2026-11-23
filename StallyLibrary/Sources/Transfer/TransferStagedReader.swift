import Darwin
import Foundation

/// Copies only validated references while holding coordinated provider access.
/// openat/O_NOFOLLOW preserves the component-resolution boundary used by MHFilePackage.
enum TransferStagedReader {
    static func read(_ url: URL) throws -> TransferArchive {
        let accessible = url.startAccessingSecurityScopedResource()
        defer { if accessible { url.stopAccessingSecurityScopedResource() } }
        guard url.isFileURL, !url.path.utf8.contains(0) else { throw TransferError.invalidFile }
        var coordinationError: NSError?
        var result: Result<TransferArchive, any Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { coordinated in
            result = Result { try readCoordinated(coordinated) }
        }
        try Task.checkCancellation()
        if let coordinationError { throw coordinationError }
        guard let result else { throw TransferError.invalidFile }
        return try result.get()
    }

    private static func readCoordinated(_ url: URL) throws -> TransferArchive {
        let root = open(url.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK)
        guard root >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        defer { close(root) }
        var info = stat()
        guard fstat(root, &info) == 0 else { throw TransferError.invalidFile }
        let isPackage = info.st_mode & S_IFMT == S_IFDIR
        guard isPackage || info.st_mode & S_IFMT == S_IFREG else { throw TransferError.invalidFile }
        let budget = TransferBudget.current
        let staging = try TransferStaging()
        try copy(
            isPackage ? ["manifest.json"] : [],
            root: root,
            to: staging.directory.appending(path: "manifest.json"),
            limit: budget.jsonBytes
        )
        let manifest = try TransferCodec.decode(staging.data(path: "manifest.json"), budget: budget)
        for photo in manifest.itemPhotos {
            guard let path = photo.image.path else { continue }
            guard isPackage, let byteCount = photo.image.byteCount else { throw TransferError.invalidFile }
            // TransferValidation has already restricted this to assets/<UUID>.<image-extension>.
            try autoreleasepool {
                try copy(
                    path.components(separatedBy: "/"),
                    root: root,
                    to: staging.directory.appending(path: path),
                    limit: byteCount
                )
                try TransferMedia.validate(staging.data(path: path), image: photo.image)
            }
        }
        return .init(manifest: manifest, staging: staging)
    }

    private static func copy(_ components: [String], root: Int32, to destination: URL, limit: Int) throws {
        var descriptor = dup(root)
        guard descriptor >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        defer { close(descriptor) }
        for (index, name) in components.enumerated() {
            let flags = O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK
            let child = openat(descriptor, name, index == components.count - 1 ? flags : flags | O_DIRECTORY)
            guard child >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
            close(descriptor)
            descriptor = child
        }
        var info = stat()
        guard fstat(descriptor, &info) == 0, info.st_mode & S_IFMT == S_IFREG, info.st_size >= 0 else {
            throw TransferError.invalidFile
        }
        guard info.st_size <= limit else { throw TransferError.limitExceeded }
        try TransferStaging.checkSpace(bytes: Int(info.st_size), at: destination.deletingLastPathComponent())
        let filePermissions: mode_t = 0o600
        let output = open(destination.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, filePermissions)
        guard output >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        defer { close(output) }
        let reader = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        let writer = FileHandle(fileDescriptor: output, closeOnDealloc: false)
        let chunkBytes = 65_536
        var remaining = limit
        while true {
            let count = try autoreleasepool {
                try Task.checkCancellation()
                guard let chunk = try reader.read(upToCount: min(chunkBytes, remaining + 1)), !chunk.isEmpty else {
                    return 0
                }
                guard chunk.count <= remaining else { throw TransferError.limitExceeded }
                try writer.write(contentsOf: chunk)
                return chunk.count
            }
            if count == 0 { break }
            remaining -= count
        }
    }
}
