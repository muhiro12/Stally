import Foundation
import MHPlatformCore
import Observation

/// Shares update evidence across app presentation and data-writing entry points.
@preconcurrency
@MainActor
@Observable
public final class RemoteUpdateOperations {
    /// Whether this environment participates in remote update checks.
    public let isEnabled: Bool
    /// The latest package-owned evaluation; unavailable evidence is not a confirmed requirement.
    public var evaluation: MHRemoteUpdateEvaluation? { adapter.evaluation }

    /// The last observed decision, updated by preparation and mutation checks.
    public var decision: MHRemoteUpdateDecision {
        evaluation?.decision ?? .unavailable
    }

    private let adapter: MHRemoteUpdateAdapter
    private let configurationError: (any Error)?

    /// Disables remote checks for previews and isolated environments.
    public init() {
        isEnabled = false
        adapter = .preview()
        configurationError = nil
    }

    /// Uses one controller for the environment's UI and headless operations.
    public init(controller: MHRemoteUpdateController) {
        isEnabled = true
        adapter = .init(controller: controller)
        configurationError = nil
    }

    /// Retains a setup failure for diagnostics while preserving offline access.
    public init(configurationError: any Error) {
        isEnabled = true
        adapter = .preview()
        self.configurationError = configurationError
    }

    /// Restores and refreshes evidence at startup, foreground entry, or explicit retry.
    @discardableResult
    public func prepare() async throws -> MHRemoteUpdateController.Preparation? {
        try Task.checkCancellation()
        if let configurationError {
            throw configurationError
        }
        return try await adapter.prepare()
    }

    /// Restores retained evidence without fetching on each edit. Unavailable evidence permits offline edits.
    public func checkMutationAllowed() async throws {
        try await performMutation { () }
    }

    /// Runs a synchronous write immediately after checking retained evidence and cancellation.
    public func performMutation<Value>(
        _ operation: () throws -> Value
    ) async throws -> Value {
        do {
            return try await adapter.perform(policy: .allowWhenUnavailable, operation)
        } catch MHRemoteUpdateOperationError.updateRequired {
            throw RemoteUpdateError.updateRequired
        }
    }
}
