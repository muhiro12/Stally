import Foundation
import MHPlatform

enum StallyDiagnostics {
    private static let namespace = "com.muhiro12.stally"

    static let loggingSnapshotKey = MHCodablePreferenceKey<[MHLogEvent]>(
        namespace: namespace,
        name: "logging.lastSession"
    )

    static var debugModeKey: MHBoolPreferenceKey {
#if DEBUG
        .init(
            namespace: namespace,
            name: "debugModeEnabled",
            default: true
        )
#else
        .init(
            namespace: namespace,
            name: "debugModeEnabled",
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
            snapshotKey: loggingSnapshotKey,
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
        .init(
            userDefaults: makeUserDefaults(
                suiteName: configuration.preferencesSuiteName
            )
        )
    }

    static func makeUserDefaults(
        suiteName: String?
    ) -> UserDefaults {
        guard let normalizedSuiteName = normalizedSuiteName(
            suiteName
        ),
            let userDefaults = UserDefaults(
                suiteName: normalizedSuiteName
            ) else {
            return .standard
        }

        return userDefaults
    }

    static func normalizedSuiteName(
        _ text: String?
    ) -> String? {
        guard let text else {
            return nil
        }

        let normalizedText = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard normalizedText.isEmpty == false else {
            return nil
        }

        return normalizedText
    }
}
