import Foundation
import StallyLibrary

actor SearchIndexTestSink: ItemSearchIndexSink {
    enum Failure: Error {
        case interrupted
    }

    private var indexedRows = [UUID: ItemSearchIndexEntry]()
    private var shouldFail = false
    private var shouldFailRemoval = false
    private var writes = 0
    private var resets = 0

    func failNextUpsert() {
        shouldFail = true
    }

    func failNextRemoval() {
        shouldFailRemoval = true
    }

    func upsert(_ entries: [ItemSearchIndexEntry]) throws {
        writes += 1
        for entry in entries {
            indexedRows[entry.uuid] = entry
        }
        if shouldFail {
            shouldFail = false
            throw Failure.interrupted
        }
    }

    func remove(_ identifiers: [UUID]) throws {
        writes += 1
        if shouldFailRemoval {
            shouldFailRemoval = false
            throw Failure.interrupted
        }
        for identifier in identifiers {
            indexedRows[identifier] = nil
        }
    }

    func rows() -> [UUID: ItemSearchIndexEntry] {
        indexedRows
    }

    func writeCount() -> Int {
        writes
    }

    func resetNamespace() {
        resets += 1
        indexedRows = [:]
    }

    func resetCount() -> Int {
        resets
    }
}
