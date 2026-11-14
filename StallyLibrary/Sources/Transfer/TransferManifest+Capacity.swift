import Foundation

extension TransferManifest {
    func estimatedJSONBytes() throws -> Int { try estimatedJSONBytes(budget: .current) }

    /// Avoid serializing the entire document merely to estimate disk and memory requirements.
    func estimatedJSONBytes(budget: TransferBudget) throws -> Int {
        try budget.check(recordCount: recordCount)
        let recordOverhead = 512
        let referenceOverhead = 48
        let controlBoundary: UInt8 = 0x20
        let quote: UInt8 = 0x22
        let backslash: UInt8 = 0x5C
        let escapedControlBytes = 6
        let escapedCharacterBytes = 2
        var bytes = recordOverhead
        func add(_ count: Int) throws {
            guard count <= budget.jsonBytes - bytes else { throw TransferError.limitExceeded }
            bytes += count
        }
        func text(_ value: String?) throws {
            guard let value else {
                return
            }
            for byte in value.utf8 {
                try add(
                    byte < controlBoundary
                        ? escapedControlBytes : (byte == quote || byte == backslash ? escapedCharacterBytes : 1)
                )
            }
        }
        try add(recordCount * recordOverhead)
        for item in items {
            try text(item.name)
            try text(item.note)
            try text(item.representativeURL)
            for _ in item.tagUUIDs { try add(referenceOverhead) }
        }
        for mark in itemMarks { try text(mark.localDateTime) }
        for period in itemPeriods {
            try text(period.startLocalDate)
            try text(period.endLocalDate)
        }
        for photo in itemPhotos { try text(photo.caption) }
        for tag in tags { try text(tag.name) }
        return bytes
    }
}
