import SwiftUI

extension EnvironmentValues {
    private struct StallyMHUIThemeMetricsKey: EnvironmentKey {
        static let defaultValue = StallyMHUIThemeMetrics.standard
    }

    var stallyMHUIThemeMetrics: StallyMHUIThemeMetrics {
        get {
            self[StallyMHUIThemeMetricsKey.self]
        }
        set {
            self[StallyMHUIThemeMetricsKey.self] = newValue
        }
    }
}
