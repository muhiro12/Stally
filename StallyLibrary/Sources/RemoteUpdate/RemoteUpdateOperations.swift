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
    public private(set) var evaluation: MHRemoteUpdateEvaluation?

    /// The last observed decision, updated by preparation and mutation checks.
    public var decision: MHRemoteUpdateDecision {
        evaluation?.decision ?? .unavailable
    }

    private let controller: MHRemoteUpdateController?
    private let configurationError: (any Error)?

    /// Disables remote checks for previews and isolated environments.
    public init() {
        isEnabled = false
        controller = nil
        configurationError = nil
    }

    /// Uses one controller for the environment's UI and headless operations.
    public init(controller: MHRemoteUpdateController) {
        isEnabled = true
        self.controller = controller
        configurationError = nil
    }

    /// Retains a setup failure for diagnostics while preserving offline access.
    public init(configurationError: any Error) {
        isEnabled = true
        controller = nil
        self.configurationError = configurationError
    }

    /// Restores and refreshes evidence at startup, foreground entry, or explicit retry.
    @discardableResult
    public func prepare() async throws -> MHRemoteUpdateController.Preparation? {
        try Task.checkCancellation()
        if let configurationError {
            throw configurationError
        }
        guard let controller else {
            return nil
        }
        let preparation = try await controller.prepare()
        evaluation = preparation.evaluation
        return preparation
    }

    /// Rechecks retained evidence immediately before a write, including timed activation.
    ///
    /// Stally's local records remain usable offline when evidence is unavailable.
    /// This check restores and merges evidence without adding networking to each edit.
    /// A confirmed requirement always blocks, including from App Intents.
    public func checkMutationAllowed() async throws {
        try Task.checkCancellation()
        guard let controller else {
            return
        }
        do {
            try await controller.checkOperationAllowed(for: .allowWhenUnavailable)
            evaluation = await controller.evaluation()
            try Task.checkCancellation()
            try decision.checkOperationAllowed(whenUnavailable: .allow)
        } catch {
            evaluation = await controller.evaluation()
            if error is CancellationError || Task.isCancelled {
                throw CancellationError()
            }
            if (error as? MHRemoteUpdateOperationError) == .updateRequired {
                throw RemoteUpdateError.updateRequired
            }
            throw error
        }
    }

    /// Runs a write and its success effects without another suspension after the check.
    public func performMutation<Value>(
        _ operation: () throws -> Value
    ) async throws -> Value {
        try await checkMutationAllowed()
        try Task.checkCancellation()
        return try operation()
    }
}
