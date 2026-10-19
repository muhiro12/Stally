#if DEBUG
import Foundation
import MHPlatform

enum StallyRemoteUpdatePreview {
    @MainActor
    static func makeOperations() -> RemoteUpdateOperations {
        do {
            guard let minimumVersion = MHAppVersion("2.0") else {
                throw MHRemoteUpdateController.Failure.invalidConfiguration
            }
            let schedule = try MHRemoteUpdateSchedule(
                bundleIdentifier: "com.muhiro12.Stally",
                revision: 1,
                requirement: .init(minimumVersion: minimumVersion, effectiveAt: .distantPast)
            )
            return .init(controller: try .init(
                bundleIdentifier: schedule.bundleIdentifier,
                storefront: nil,
                policyLifetime: MHRemoteUpdateController.Defaults.policyLifetime,
                publicationLifetime: MHRemoteUpdateController.Defaults.publicationLifetime,
                store: nil,
                currentVersion: { "1.0" },
                fetchSchedule: {
                    .init(value: schedule, fetchedAt: .now)
                },
                publicVersion: { .init("2.0") }
            ))
        } catch {
            return .init(configurationError: error)
        }
    }
}
#endif
