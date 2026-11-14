import Foundation
import os

/// Admission estimates reserve headroom for decoding, review and the single pending save.
/// These are runtime resource checks, not format limits or guarantees against memory pressure.
struct TransferBudget: Sendable {
    static var current: Self {
        let physicalDivisor: UInt64 = 4
        let physical = Int(clamping: ProcessInfo.processInfo.physicalMemory / physicalDivisor)
        #if (os(iOS) || os(visionOS)) && !targetEnvironment(simulator)
        let headroomDivisor = 2
        return .init(memoryBytes: min(physical, os_proc_available_memory() / headroomDivisor))
        #else
        return .init(memoryBytes: physical)
        #endif
    }

    let memoryBytes: Int

    var jsonBytes: Int {
        let decodingMultiplier = 8
        return memoryBytes / decodingMultiplier
    }
    var recordCount: Int {
        let pendingRecordBytes = 8_192
        return memoryBytes / pendingRecordBytes
    }

    func check(jsonBytes: Int) throws {
        guard jsonBytes >= 0, jsonBytes <= self.jsonBytes else { throw TransferError.limitExceeded }
    }

    func check(recordCount: Int) throws {
        guard recordCount >= 0, recordCount <= self.recordCount else { throw TransferError.limitExceeded }
    }
}
