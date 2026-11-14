import Foundation
import MHPlatformCore
import StallyLibrary
import Synchronization
import Testing

@MainActor
struct RemoteUpdateOperationsTests {
    @Test
    func confirmedUpdateBlocksMutationAndSuccessEffects() async throws {
        let fixture = try Fixture()
        try await fixture.operations.prepare()
        var didWrite = false
        await #expect(throws: RemoteUpdateError.updateRequired) {
            try await fixture.operations.performMutation {
                didWrite = true
            }
        }
        #expect(!didWrite)
        #expect(fixture.operations.decision == .updateRequired)
    }

    @Test
    func noRequirementAllowsMutation() async throws {
        let fixture = try Fixture(hasRequirement: false)
        try await fixture.operations.prepare()
        let value = try await fixture.operations.performMutation { "saved" }
        #expect(value == "saved")
        #expect(fixture.operations.evaluation?.reason == .noActiveRequirement)
    }

    @Test
    func unavailableNetworkDoesNotBlockOfflineRecords() async throws {
        let fixture = try Fixture()
        fixture.source.fail()
        let preparation = try await fixture.operations.prepare()
        #expect(preparation?.refreshError != nil)
        let value = try await fixture.operations.performMutation { "offline" }
        #expect(value == "offline")
        #expect(fixture.operations.decision == .unavailable)
    }

    @Test
    func unpublishedMinimumDoesNotForceAnUpdate() async throws {
        let fixture = try Fixture(published: false)
        try await fixture.operations.prepare()
        let value = try await fixture.operations.performMutation { "saved" }
        #expect(value == "saved")
        #expect(fixture.operations.decision == .unavailable)
    }

    @Test
    func timedRequirementIsCheckedAtMutationWithoutAnotherFetch() async throws {
        let fixture = try Fixture(activationDelay: 60)
        try await fixture.operations.prepare()
        #expect(fixture.operations.decision == .notRequired)
        fixture.clock.advance(by: 60)
        await #expect(throws: RemoteUpdateError.updateRequired) {
            try await fixture.operations.performMutation { "must not save" }
        }
        #expect(fixture.operations.decision == .updateRequired)
    }

    @Test
    func failedRefreshRetainsAConfirmedRequirement() async throws {
        let fixture = try Fixture()
        try await fixture.operations.prepare()
        fixture.source.fail()
        let preparation = try await fixture.operations.prepare()
        #expect(preparation?.refreshError != nil)
        await #expect(throws: RemoteUpdateError.updateRequired) {
            try await fixture.operations.performMutation { "must not save" }
        }
    }

    @Test
    func expiredPublicationEvidenceRestoresOfflineAccess() async throws {
        let fixture = try Fixture()
        try await fixture.operations.prepare()
        fixture.clock.advance(by: MHRemoteUpdateController.Defaults.publicationLifetime + 1)
        let value = try await fixture.operations.performMutation { "offline" }
        #expect(value == "offline")
        #expect(fixture.operations.evaluation?.reason == .publicationExpired)
    }

    @Test
    func cancellationNeverRunsTheMutation() async throws {
        let fixture = try Fixture(hasRequirement: false)
        var didWrite = false
        let task = Task {
            try await fixture.operations.performMutation {
                didWrite = true
            }
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(!didWrite)
    }

    @Test
    func previewsDoNotNeedRemoteEvidence() async throws {
        let operations = RemoteUpdateOperations()
        #expect(!operations.isEnabled)
        let preparation = try await operations.prepare()
        #expect(preparation == nil)
        let value = try await operations.performMutation { "preview" }
        #expect(value == "preview")
    }
}

private extension RemoteUpdateOperationsTests {
    @MainActor
    struct Fixture {
        let clock = Clock()
        let source = Source()
        let operations: RemoteUpdateOperations

        init(hasRequirement: Bool = true, published: Bool = true, activationDelay: TimeInterval = 0) throws {
            let version = try #require(MHAppVersion("2.0"))
            let schedule = try MHRemoteUpdateSchedule(
                bundleIdentifier: "com.muhiro12.Stally",
                revision: 1,
                requirement: hasRequirement ? .init(
                    minimumVersion: version,
                    effectiveAt: clock.now().addingTimeInterval(activationDelay)
                ) : nil
            )
            let testClock = clock
            let testSource = source
            operations = .init(controller: try .init(
                bundleIdentifier: schedule.bundleIdentifier,
                storefront: nil,
                policyLifetime: MHRemoteUpdateController.Defaults.policyLifetime,
                publicationLifetime: MHRemoteUpdateController.Defaults.publicationLifetime,
                store: nil,
                currentVersion: { "1.0" },
                now: { testClock.now() },
                fetchSchedule: {
                    try testSource.check()
                    return .init(value: schedule, fetchedAt: testClock.now())
                },
                publicVersion: { published ? version : nil }
            ))
        }
    }

    final class Clock: Sendable {
        private static let initialTimestamp = 2_000_000_000.0
        private let date = Mutex(Date(timeIntervalSince1970: Clock.initialTimestamp))

        func now() -> Date {
            date.withLock { $0 }
        }

        func advance(by interval: TimeInterval) {
            date.withLock { $0.addTimeInterval(interval) }
        }
    }

    final class Source: Sendable {
        private let shouldFail = Mutex(false)

        func fail() {
            shouldFail.withLock { $0 = true }
        }

        func check() throws {
            if shouldFail.withLock({ $0 }) {
                throw URLError(.notConnectedToInternet)
            }
        }
    }
}
