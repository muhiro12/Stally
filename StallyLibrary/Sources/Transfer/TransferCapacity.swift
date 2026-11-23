import Foundation
import SwiftData

/// A conservative preflight complements, rather than replaces, native atomic-save errors.
enum TransferCapacity {
    static func check(_ archive: TransferArchive, context: ModelContext) throws {
        let mediaBytes = archive.manifest.itemPhotos.reduce(0) { $0 + ($1.image.byteCount ?? 0) }
        let stagingCopies = 2
        try TransferBudget.current.check(recordCount: archive.manifest.recordCount)
        let requested = Int64((mediaBytes + (try archive.manifest.estimatedJSONBytes())) * stagingCopies)
        for configuration in context.container.configurations where !configuration.isStoredInMemoryOnly {
            let directory = configuration.url.deletingLastPathComponent()
            let capacity = try directory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let available = capacity.volumeAvailableCapacityForImportantUsage, available < requested {
                throw CocoaError(.fileWriteOutOfSpace)
            }
        }
    }
}
