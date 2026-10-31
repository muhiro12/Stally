import Foundation
import StallyLibrary
import SwiftData

@MainActor
enum IntentAccess {
    static func read<Value>(container: ModelContainer, operation: (ModelContext) throws -> Value) throws -> Value {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        do { return try operation(context) } catch { throw StallyIntentError(message: error.localizedDescription) }
    }

    static func write<Value>(
        container: ModelContainer,
        updates: RemoteUpdateOperations,
        operation: (ModelContext) throws -> Value
    ) async throws -> Value {
        do {
            return try await updates.performMutation { try read(container: container, operation: operation) }
        } catch { throw StallyIntentError(message: error.localizedDescription) }
    }
}
