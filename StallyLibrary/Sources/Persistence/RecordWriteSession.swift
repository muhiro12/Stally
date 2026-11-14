import Foundation
import Observation

/// Binds a pending edit or review to the native account session in which it began.
@preconcurrency
@MainActor
@Observable
public final class RecordWriteSession {
    private let updates: RemoteUpdateOperations
    private var isCurrent = true

    /// Starts a write scope using the environment’s shared update guard.
    public init(updates: RemoteUpdateOperations) {
        self.updates = updates
    }

    /// Invalidates existing writers even if the replacement account contains identical records.
    public func invalidate() {
        isCurrent = false
    }

    /// Rejects work that outlived its account session.
    public func checkCurrent() throws {
        guard isCurrent else { throw RecordSessionError.accountChanged }
    }

    /// Rechecks the session after any suspension in the update guard, immediately before saving.
    public func performMutation<Value>(_ operation: () throws -> Value) async throws -> Value {
        try checkCurrent()
        return try await updates.performMutation {
            try checkCurrent()
            return try operation()
        }
    }
}
