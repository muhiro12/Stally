import Foundation
import SwiftData

/// A conservative preflight complements, rather than replaces, native atomic-save errors.
enum TransferCapacity {
    static func check(_ archive: TransferArchive, context: ModelContext) throws {
        let mediaBytes = archive.media.values.reduce(0) { $0 + $1.count }
        let stagingCopies = 2
        let requested = Int64((mediaBytes + (try TransferCodec.encode(archive.manifest)).count) * stagingCopies)
        for configuration in context.container.configurations where !configuration.isStoredInMemoryOnly {
            let directory = configuration.url.deletingLastPathComponent()
            let capacity = try directory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let available = capacity.volumeAvailableCapacityForImportantUsage, available < requested {
                throw CocoaError(.fileWriteOutOfSpace)
            }
        }
    }
}
