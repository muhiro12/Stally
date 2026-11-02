//
//  StallyLinkOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import MHPlatformCore

/// Cross-surface shareable link use cases.
public enum StallyLinkOperations {
    /// Product URL scheme.
    public static let scheme = "stally"

    /// Builds a shareable URL for a supported Stally link.
    public static func url(for link: StallyLink) -> URL {
        guard let url = codec.url(for: link, transport: .customScheme) else {
            preconditionFailure("A supported Stally route must produce a valid URL.")
        }
        return url
    }

    /// Parses an incoming URL into a supported Stally link.
    public static func parse(_ url: URL) -> StallyLinkParseResult {
        if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            guard url.scheme?.lowercased() == "https", url.pathComponents.dropFirst().first == "Stally",
                  url.user == nil, url.password == nil, url.port == nil else {
                return .unsupported
            }
        }
        guard let link = codec.parse(url) else {
            return .unsupported
        }
        return .supported(link)
    }
}

private extension StallyLinkOperations {
    static let codec = MHDeepLinkCodec<StallyLink>(
        configuration: .init(
            customScheme: scheme,
            preferredUniversalLinkHost: "muhiro12.github.io",
            allowedUniversalLinkHosts: ["muhiro12.github.io"],
            universalLinkPathPrefix: "Stally",
            preferredTransport: .customScheme
        )
    )
}
