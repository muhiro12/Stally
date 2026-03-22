import SwiftUI

/// App-local mirror of the public MHUI standard spacing and radius tokens.
/// Stally uses these values directly because MHUI 1.0 keeps them internal.
struct StallyMHUIThemeMetrics: Sendable, Equatable {
    struct Spacing: Sendable, Equatable {
        let inline: CGFloat
        let control: CGFloat
        let group: CGFloat
        let section: CGFloat
        let screen: CGFloat
    }

    struct Radius: Sendable, Equatable {
        let control: CGFloat
        let surface: CGFloat
        let pill: CGFloat
    }

    let spacing: Spacing
    let radius: Radius

    static let standard = Self(
        spacing: .init(
            inline: 4,
            control: 12,
            group: 20,
            section: 32,
            screen: 40
        ),
        radius: .init(
            control: 8,
            surface: 12,
            pill: 999
        )
    )
}

private struct StallyMHUIThemeMetricsKey: EnvironmentKey {
    static let defaultValue = StallyMHUIThemeMetrics.standard
}

extension EnvironmentValues {
    var stallyMHUIThemeMetrics: StallyMHUIThemeMetrics {
        get {
            self[StallyMHUIThemeMetricsKey.self]
        }
        set {
            self[StallyMHUIThemeMetricsKey.self] = newValue
        }
    }
}
