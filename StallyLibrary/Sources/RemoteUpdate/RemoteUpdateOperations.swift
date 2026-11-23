import Foundation
import MHPlatformCore
import Observation
import os

/// Shares update evidence across app presentation and data-writing entry points.
@preconcurrency
@MainActor
@Observable
public final class RemoteUpdateOperations {
    /// Whether this environment participates in remote update checks.
    public let isEnabled: Bool
    /// The current session's announcements, filtered by the view at presentation time.
    public private(set) var announcementFeed: MHAnnouncementFeed?
    /// The latest package-owned evaluation; unavailable evidence is not a confirmed requirement.
    public var evaluation: MHRemoteUpdateEvaluation? { adapter.evaluation }

    /// The last observed decision, updated by preparation and mutation checks.
    public var decision: MHRemoteUpdateDecision {
        evaluation?.decision ?? .unavailable
    }

    private let adapter: MHRemoteUpdateAdapter
    private let configurationError: (any Error)?
    private let pendingAnnouncements = OSAllocatedUnfairLock<MHRemoteConfigSection<MHAnnouncementFeed>?>(
        initialState: nil
    )

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

    /// Receives notices from the same configuration request that refreshes the update policy.
    public init(
        appStoreID: Int,
        configurationURL: URL,
        storageDirectory: URL? = nil,
        session: URLSession = .shared
    ) throws {
        let pending = pendingAnnouncements
        let controller = try MHRemoteUpdateController(
            appStoreID: appStoreID,
            configurationURL: configurationURL,
            storageDirectory: storageDirectory,
            session: session
        ) { response in
            pending.withLock { $0 = response.value }
        }
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
        defer {
            // A valid announcement can arrive even when the sibling update policy fails.
            let section = pendingAnnouncements.withLock { pending in
                defer { pending = nil }
                return pending
            }
            if let section {
                announcementFeed = try? section.get()
            }
        }
        return try await adapter.prepare()
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
