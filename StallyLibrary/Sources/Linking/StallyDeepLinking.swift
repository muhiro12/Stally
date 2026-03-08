import MHDeepLinking

/// Shared deep-link configuration and codec factory for Stally routes.
public enum StallyDeepLinking {
    /// Canonical deep-link configuration for custom-scheme and universal-link routes.
    public static let configuration = MHDeepLinkConfiguration(
        customScheme: "stally",
        preferredUniversalLinkHost: "stally.muhiro12.com",
        allowedUniversalLinkHosts: ["stally.muhiro12.com"],
        universalLinkPathPrefix: "app",
        preferredTransport: .customScheme
    )

    /// Builds a codec for parsing and generating `StallyRoute` URLs.
    public static func codec() -> MHDeepLinkCodec<StallyRoute> {
        .init(configuration: configuration)
    }
}
