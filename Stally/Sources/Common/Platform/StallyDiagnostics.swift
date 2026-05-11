import Foundation
import MHPlatform

enum StallyDiagnostics {
    private static let namespace = "com.muhiro12.stally"

    static let loggingSnapshotStorageDescriptors = MHLogSnapshotStorageDescriptors(
        current: .init(
            storageKey: "\(namespace).logging.currentSession",
            defaultSelection: .standard
        ),
        previous: .init(
            storageKey: "\(namespace).logging.previousSession",
            defaultSelection: .standard
        )
    )

    static var debugModeKey: MHBoolPreferenceDescriptor {
        #if DEBUG
        .init(
            storageKey: "\(namespace).debugModeEnabled",
            defaultSelection: .standard,
            default: true
        )
        #else
        .init(
            storageKey: "\(namespace).debugModeEnabled",
            defaultSelection: .standard,
            default: false
        )
        #endif
    }

    static var defaultDebugModeEnabled: Bool {
        debugModeKey.defaultValue
    }

    static func makeLoggingBootstrap(
        configuration: MHAppConfiguration
    ) -> MHLoggingBootstrap {
        let preferenceStore = makePreferenceStore(
            configuration: configuration
        )

        return .init(
            captureLevel: captureLevel(
                isDebugModeEnabled: loadDebugMode(
                    from: preferenceStore
                )
            ),
            subsystem: subsystem,
            snapshotStorageDescriptors: loggingSnapshotStorageDescriptors,
            snapshotStore: preferenceStore
        )
    }

    static func loadDebugMode(
        from store: MHPreferenceStore
    ) -> Bool {
        store.bool(for: debugModeKey)
    }

    static func saveDebugMode(
        _ isEnabled: Bool,
        in store: MHPreferenceStore
    ) {
        store.set(
            isEnabled,
            for: debugModeKey
        )
    }

    static func captureLevel(
        isDebugModeEnabled: Bool
    ) -> MHLogLevel {
        isDebugModeEnabled ? .debug : .notice
    }
}

private extension StallyDiagnostics {
    static var subsystem: String {
        Bundle.main.bundleIdentifier ?? namespace
    }

    static func makePreferenceStore(
        configuration: MHAppConfiguration
    ) -> MHPreferenceStore {
        _ = configuration
        return .init()
    }
}
